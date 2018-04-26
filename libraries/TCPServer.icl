implementation module TCPServer

import System._Pointer
import Data.Func
import StdEnv

import Data.Maybe
import Data.Tuple
import System.Time
import TCPIP
import Data.Error
import Data.List

handlerResponse :: !.st -> *(HandlerResponse ci .st)
handlerResponse s =
	{ globalState   = s  , newConnection   = []
	, newListener   = [] , sendData        = []
	, closeListener = [] , closeConnection = []
	, stop          = False
	}

emptyServer :: Server ci .st
emptyServer =
	{ Server
	| idleTimeout     = Just 1000
	, sendTimeout     = Nothing
	, connectTimeout  = Nothing
	, onInit          = \        s w->(handlerResponse s, w)
	, onData          = \    d c s w->(Nothing, c, handlerResponse s, w)
	, onTick          = \        s w->(handlerResponse s, w)
	, onClientClose   = \      _ s w->(handlerResponse s, w)
	, onListenerClose = \  p     s w->(handlerResponse s, w)
	, onClose         = \        s w->(s, w)
	}

msToTimespec :: Int -> Timespec
msToTimespec m = {tv_sec=m/1000,tv_nsec=(m rem 1000)*1000000}

selectList :: .Int u:[.a] -> (.a,v:[.a]), [u <= v]
selectList n l = let (left, [el:right]) = splitAt n l in (el, left++right)

selectListMultiple :: (.a -> (.Bool,.b)) ![.a] -> ([.b],[.b])
selectListMultiple p [] = ([], [])
selectListMultiple p [x:xs]
# (left, x) = p x
# (lefts, rest) = selectListMultiple p xs
| left = ([x:lefts], rest)
       = (lefts, [x:rest])

usleep :: !Int !*w -> (!Int, !*w)
usleep t w = code {
		ccall usleep "I:I:A"
	}

serve :: (Server ci .st) .st !*World -> *(Maybe String, !.st, !*World) | == ci
serve server s w
# (r, w) = server.onInit s w
= cont server [] [] r 0 w

tous :: Timespec -> Int
tous {tv_sec,tv_nsec} = tv_sec*1000000+tv_nsec/1000

loop :: (Server ci .st)
	*[*( *(TCP_Listener_ *(IPAddress,*(DuplexChannel *TCP_SChannel_ *TCP_RChannel_ ByteSeq)))
	   , Listener ci .st)]
	*[*( *(TCP_SChannel_ ByteSeq)
	   , *(TCP_RChannel_ ByteSeq)
	   , Connection ci .st)]
	.st
	Int
	!*World
	-> (.(Maybe {#Char}),.st,!.World) | == ci
loop server listeners channels s lastOnTick w
# (ts, w) = appFst tous $ nsTime w
//Do the select
# (sChans, rChans, crecords) = unzip3 channels
# (listeners, lrecords) = unzip listeners
# (numl, listeners) = getNrOfChannels (TCP_Listeners listeners)
# (numc, channels) = getNrOfChannels (TCP_RChannels rChans)
# timeoutus = max 0 $ maybe 0 ((*)1000) server.idleTimeout - (ts - lastOnTick)
# (selectSet, TCP_Pair (TCP_Listeners listeners) (TCP_RChannels rChans), _, w)
	= if (numl + numc == 0)
		([], TCP_Pair (TCP_Listeners []) (TCP_RChannels []), TCP_Void, snd $ usleep timeoutus w)
		(selectChannel_MT (Just (timeoutus/1000)) (TCP_Pair listeners channels) TCP_Void w)
# channels = zip3 sChans rChans crecords
# listeners = zip2 listeners lrecords
//See what time it is now, if nothing happened we sleep some more after the tick
= case selectSet of
	//Nothing
	[] //See wether the last tick was passed
		# (r, w) = server.onTick s w
		# (ts, w) = appFst tous $ nsTime w
		= cont server listeners channels r ts w
	[(index, what):_]
		//New connection
		| index < numl
			//Select
			# ((lst, lrecord), listeners) = selectList index listeners
			//Receive
			# (tReport, mbNewMember, lst, w) = receive_MT (Just 0) lst w
			| tReport <> TR_Success 
				# (bail, r, w) = lrecord.Listener.onError ListenerUnableToAnswer s w
				| bail = (Just "Unable to answer connected client", r.globalState, w)
				= cont server listeners channels r lastOnTick w
			# (ip,{rChannel,sChannel}) = fromJust mbNewMember
			//Run onConnect
			# (md, crecord, r, w) = lrecord.Listener.onConnect (toString ip) lrecord.Listener.port s w
			//Maybe send
			# (sChannel, w) = maybeSend server.sendTimeout md sChannel w
			# crecord = {crecord & host=(toString ip), port=lrecord.Listener.port} 
			= cont server (listeners ++ [(lst, lrecord)]) (channels ++ [(sChannel,rChannel, crecord)]) r lastOnTick w
		//Data from existing connection
		| what =: SR_Available
			//Select
			# ((sChannel,rChannel, crecord), channels) = selectList (index - numl) channels
			//Receive
			# (byteSeq, rChannel, w) = receive rChannel w
			//Run onData
			# (md, ci, r, w) = server.onData (toString byteSeq) crecord.Connection.state s w
			//Maybe send
			# (sChannel, w) = maybeSend server.sendTimeout md sChannel w
			= cont server listeners (channels ++ [(sChannel,rChannel,{Connection | crecord & state=ci})]) r lastOnTick w
		//Client closing
		| what =: SR_EOM
			# ((sChannel,rChannel, crecord), channels) = selectList (index - numl) channels
			//Run onClose
			# (r, w) = crecord.Connection.onClose crecord.Connection.state s w
			= cont server listeners channels r lastOnTick
				$ seq [closeChannel sChannel, closeRChannel rChannel] w
		//Unknown or unused select codes
		| what =: SR_Sendable
			= (Just $ "SR_Sendable on " +++ toString index, s, w)
		| what =: SR_Disconnected
			= (Just $ "SR_Disconnected on " +++ toString index, s, w)
			= (Just $ "Unknown select code: " +++ toString what +++ " on " +++ toString index, s, w)

maybeSend _ Nothing sC w = (sC, w)
maybeSend to (Just d) sC w
	# (tr, i, sC, w) = send_MT to (toByteSeq d) sC w
	= (sC, w)

seqListError [] s = (Ok [], s)
seqListError [x:xs] s = case x s of
	(Error e, s) = (Error e, s)
	(Ok a, s) = case seqListError xs s of
		(Ok as, s) = (Ok [a:as], s)
		(Error e, s) = (Error e, s)

maybeBail eh lastOnTick channels listeners server e es s w
	# (bail, r, w) = eh e s w
	| bail = (Just es, r.globalState, w)
	= cont server listeners channels r lastOnTick w

//Add listener
cont server listeners channels response=:{newListener=[lst:ls],globalState} lastOnTick w
	= case openTCP_Listener lst.Listener.port w of
		(_, Nothing, w) = maybeBail lst.Listener.onError lastOnTick channels listeners server ListenerUnableToOpen "Unable to open listener" globalState w
		(_, Just l, w) = cont server (listeners ++ [(l, lst)]) channels {response & newListener=ls} lastOnTick w
//Add connection
cont server listeners channels response=:{newConnection=[crecord:cs],globalState,closeConnection,newListener,sendData,closeListener} lastOnTick w
	# (mi, w) = lookupIPAddress crecord.Connection.host w
	| isNothing mi = maybeBail` ConnectionLookupError "Unable to lookup ip address" globalState w
	# (tr, mc, w) = connectTCP_MT server.connectTimeout (fromJust mi, crecord.Connection.port) w
	| tr =: TR_Expired = maybeBail` ConnectionTimedOut "Connection timed out" globalState w
	| tr =: TR_NoSuccess = maybeBail` ConnectionUnableToOpen "Unable to open connection" globalState w
	= case mc of
		Nothing = (Just "This shouldn't happen...", globalState, w)
		Just {rChannel,sChannel}
			# (md, ci, r, w) = crecord.Connection.onConnect crecord.Connection.state globalState w
			# (sChannel, w) = maybeSend server.sendTimeout md sChannel w
			= cont server listeners (channels ++ [(sChannel,rChannel,{Connection | crecord & state=ci})]) (mergeR r newListener cs sendData closeListener closeConnection) lastOnTick w
where
	maybeBail` = maybeBail crecord.Connection.onError lastOnTick channels listeners server 
//Remove listener
cont server listeners channels response=:{globalState,closeListener=[port:cs],newListener,newConnection,sendData,closeConnection} lastOnTick w
	# (toClose, listeners) = selectListMultiple (\(l,lst)->(lst.Listener.port==port, (l, lst))) listeners
	= case toClose of
		[] = cont server listeners channels {response & closeListener=cs} lastOnTick w
		[(l,p):xs]
			# (r, w) = server.onListenerClose port globalState w
			= cont server listeners channels (mergeR r newListener newConnection sendData [port:cs] closeConnection) lastOnTick
				$ closeRChannel l w
//Remove channel
cont server listeners channels response=:{globalState,closeConnection=[ci:cs],newListener,newConnection,sendData,closeListener} lastOnTick w
	# (toClose, channels) = selectListMultiple
		(\(s,r,crecord)->(crecord.Connection.state == ci, (s,r,crecord))) channels
	= case toClose of
		[] = cont server listeners channels {response & closeConnection=cs} lastOnTick w
		[(sc, rc, crecord):xs]
			# (r, w) = server.onClientClose crecord.Connection.state globalState w
			= cont server listeners channels (mergeR r newListener newConnection sendData closeListener [ci:cs]) lastOnTick
				$ closeChannel sc
				$ closeRChannel rc w
//Send data
cont server listeners channels response=:{sendData=[(ci, data):ds]} lastOnTick w
	= uncurry (send w) $ selectListMultiple (\(s,r,p)->(p.Connection.state==ci, (s,r,p))) channels
where
	send w [] channels = cont server listeners channels {response & sendData=ds} lastOnTick w
	send w [(sc,rc,p):xs] channels
		# (sc, w) = maybeSend server.sendTimeout (Just data) sc w
		= send w xs (channels ++ [(sc,rc,p)])
//Stop
cont server [] [] response=:{globalState,stop=True} lastOnTick w
	# (globalState, w) = server.Server.onClose globalState w
	= (Nothing, globalState, w)
cont server listeners channels response=:{stop=True} lastOnTick w
	# (listeners, lrecords) = unzip listeners
	# listeners = zip2 listeners lrecords
	# (schannels, rchannels, crecords) = unzip3 channels
	# channels = zip3 schannels rchannels crecords
	= cont server listeners channels {response & closeConnection=map (\c->c.Connection.state) crecords, closeListener=map (\l->l.Listener.port) lrecords} lastOnTick w
//Nothing to do
cont server listeners channels {globalState} lastOnTick w
	= loop server listeners channels globalState lastOnTick w

mergeR r nl nc sd cl cc = {r & newListener=nl, newConnection=nc, sendData=sd, closeListener=cl, closeConnection=cc}
