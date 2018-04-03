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

DEBUG :== True

handlerResponse :: .st -> *(HandlerResponse .st ci)
handlerResponse s =
	{ globalState   = s  , newConnection   = []
	, newListener   = [] , sendData        = []
	, closeListener = [] , closeConnection = []
	, stop          = False
	}

msToTimespec :: Int -> Timespec
msToTimespec m = {tv_sec=m/1000,tv_nsec=(m rem 1000)*1000000}

selectList :: .Int u:[.a] -> (.a,v:[.a]), [u <= v]
selectList n l = let (left, [el:right]) = splitAt n l in (el, left++right)

//selectListMultiple :: (.a -> (Bool, *a)) [.a]
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

serve ::
	(Maybe Int)
	(Maybe Int)
	(Maybe Int)
	(.st -> .(*World -> *(*(HandlerResponse .st ci), !*World)))
	(String Int -> .(.st -> .(*World -> *(Maybe String, ci, *(HandlerResponse .st ci), !*World))))
	(ci -> .(.st -> .(*World -> *(Maybe String, ci, *(HandlerResponse .st ci), !*World))))
	(String ci -> .(.st -> .(*World -> *(Maybe String, ci, *(HandlerResponse .st ci), !*World))))
	(.st -> .(*World -> *(*(HandlerResponse .st ci), !*World)))
	(ci -> .(.st -> .(*World -> *(*(HandlerResponse .st ci), !*World))))
	(Int -> .(.st -> .(*World -> *(*(HandlerResponse .st ci), !*World))))
	(.st -> .(*World -> *(.st, !*World)))
	.st
	!*World
	-> (Maybe String, .st, !*World)
	| == ci
serve idleTimeout sendTimeout connectTimeout onInit onConnect onNewSuccess onData onTick onClientClose onListenerClose onClose s w
# (r, w) = onInit s w
= cont [] [] r 0 w
where
	tous :: Timespec -> Int
	tous {tv_sec,tv_nsec} = tv_sec*1000000+tv_nsec/1000
	
	loop  listeners channels s lastOnTick w
	# (ts, w) = appFst tous $ nsTime w
	//Do the select
	# (sChans, rChans, clientstates) = unzip3 channels
	# (listeners, ports) = unzip listeners
	# (numl, listeners) = getNrOfChannels (TCP_Listeners listeners)
	# (numc, channels) = getNrOfChannels (TCP_RChannels rChans)
	# timeoutus = max 0 $ maybe 0 ((*)1000) idleTimeout - (ts - lastOnTick)
	# (selectSet, TCP_Pair (TCP_Listeners listeners) (TCP_RChannels rChans), _, w)
		= if (numl + numc == 0)
			([], TCP_Pair (TCP_Listeners []) (TCP_RChannels []), TCP_Void, snd $ usleep timeoutus w)
			(selectChannel_MT (Just (timeoutus/1000)) (TCP_Pair listeners channels) TCP_Void w)
	# listeners = zip2 listeners ports
	# channels = zip3 sChans rChans clientstates
	//See what time it is now, if nothing happened we sleep some more after the tick
	= case selectSet of
		//Nothing
		[] //See wether the last tick was passed
			# (r, w) = onTick s w
			# (ts, w) = appFst tous $ nsTime w
			= cont listeners channels r ts w
		[(index, what):_]
			//New connection
			| index < numl
	//			| not (trace_tn "new connection") = undef
				//Select
				# ((lst, port), listeners) = selectList index listeners
				//Receive
				# (tReport, mbNewMember, lst, w) = receive_MT (Just 0) lst w
				| tReport <> TR_Success = abort "couldn't connect to new client"//loop lst channels s io w
				# (ip,{rChannel,sChannel}) = fromJust mbNewMember
				//Run onConnect
				# (md, ci, r, w) = onConnect (toString ip) port s w
				//Maybe send
				# (sChannel, w) = maybeSend sendTimeout md sChannel w
				= cont (listeners ++ [(lst, port)]) (channels ++ [(sChannel,rChannel, ci)]) r lastOnTick w
			//Data from existing connection
			| what =: SR_Available
				//Select
				# ((sChannel,rChannel, ci), channels) = selectList (index - numl) channels
				//Receive
				# (byteSeq, rChannel, w) = receive rChannel w
	//			| not (trace_tn ("new data: " +++ toString byteSeq)) = undef
				//Run onData
				# (md, ci, r, w) = onData (toString byteSeq) ci s w
				//Maybe send
				# (sChannel, w) = maybeSend sendTimeout md sChannel w
				= cont listeners (channels ++ [(sChannel,rChannel,ci)]) r lastOnTick w
			//Client closing
			| what =: SR_EOM
	//			| not (trace_tn "client close") = undef
				# ((sChannel,rChannel, ci), channels) = selectList (index - numl) channels
				//Run onClose
				# (r, w) = onClientClose ci s w
				= cont listeners channels r lastOnTick
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
	
	//Add listener
	cont listeners channels response=:{newListener=[port:ls],globalState} lastOnTick w
	//	| not (trace_tn ("add listener: " +++ toString port)) = undef
		= case openTCP_Listener port w of
			(_, Nothing, w) = (Just "Couldn't open TCP_Listener", globalState, w)
			(_, Just l, w) = cont (listeners ++ [(l, port)]) channels {response & newListener=ls} lastOnTick w
	//Add connection
	cont listeners channels response=:{newConnection=[(host,port,ci):cs],globalState,closeConnection,newListener,sendData,closeListener} lastOnTick w
	//	| not (trace_tn ("add connection: " +++ host +++ ":" +++ toString port)) = undef
		# (mi, w) = lookupIPAddress host w
		| isNothing mi = (Just "Couldn't lookupIPAddress", globalState, w)
		# (tr, mc, w) = connectTCP_MT connectTimeout (fromJust mi, port) w
		| tr =: TR_Expired = (Just "Timeout expired while opening TCP", globalState, w)
		| tr =: TR_NoSuccess = (Just "No success while opening TCP", globalState, w)
		= case mc of
			Nothing = (Just "Halp?", globalState, w)
			Just {rChannel,sChannel}
				# (md, ci, r, w) = onNewSuccess ci globalState w
				# (sChannel, w) = maybeSend sendTimeout md sChannel w
				= cont listeners (channels ++ [(sChannel,rChannel,ci)]) (mergeR r newListener cs sendData closeListener closeConnection) lastOnTick w
	//Remove listener
	cont listeners channels response=:{globalState,closeListener=[port:cs],newListener,newConnection,sendData,closeConnection} lastOnTick w
	//	| not (trace_tn ("remove listener " +++ toString port)) = undef
		# (toClose, listeners) = selectListMultiple (\(l,p)->(p==port, (l, p))) listeners
		= case toClose of
			[] = cont listeners channels {response & closeListener=cs} lastOnTick w
			[(l,p):xs]
				# (r, w) = onListenerClose port globalState w
				= cont listeners channels (mergeR r newListener newConnection sendData [port:cs] closeConnection) lastOnTick
					$ closeRChannel l w
	//Remove channel
	cont listeners channels response=:{globalState,closeConnection=[ci:cs],newListener,newConnection,sendData,closeListener} lastOnTick w
		# (toClose, channels) = selectListMultiple (\(s,r,p)->(p==ci, (s,r,p))) channels
		= case toClose of
			[] = cont listeners channels {response & closeConnection=cs} lastOnTick w
			[(sc,rc,p):xs]
	//			| not (trace_tn ("remove channel")) = undef
				# (r, w) = onClientClose p globalState w
				= cont listeners channels (mergeR r newListener newConnection sendData closeListener [ci:cs]) lastOnTick
					$ closeChannel sc
					$ closeRChannel rc w
	//Send data
	cont listeners channels response=:{sendData=[(ci, data):ds]} lastOnTick w
	//	| not (trace_tn ("Send data: " +++ data)) = undef
		= uncurry (send w) $ selectListMultiple (\(s,r,p)->(p==ci, (s,r,p))) channels
	where
		send w [] channels = cont listeners channels {response & sendData=ds} lastOnTick w
		send w [(sc,rc,p):xs] channels
			# (sc, w) = maybeSend sendTimeout (Just data) sc w
			= send w xs (channels ++ [(sc,rc,p)])
		
	//Stop
	cont [] [] response=:{globalState,stop=True} lastOnTick w
		# (st, w) = (onClose globalState w)
		= (Nothing, st, w)
	cont listeners channels response=:{stop=True} lastOnTick w
	//	| not (trace_tn "Stop") = undef
		# (listeners, ports) = unzip listeners
		# listeners = zip2 listeners ports
		# (schannels, rchannels, cids) = unzip3 channels
		# channels = zip3 schannels rchannels cids
		= cont listeners channels {response & closeConnection=cids, closeListener=ports} lastOnTick w
	//Nothing to do
	cont listeners channels {globalState} lastOnTick w
		= loop listeners channels globalState lastOnTick w
	
	mergeR r nl nc sd cl cc = {r & newListener=nl, newConnection=nc, sendData=sd, closeListener=cl, closeConnection=cc}
