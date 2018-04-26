implementation module TCPServer.Connection

import StdEnv
import TCPServer
import Data.Maybe
import Data.Tuple
import Data.Error

connect :: String Int (ConnectionHandlers .st) .st !*World -> *(Maybe String, .st, !*World)
connect host port {ConnectionHandlers|onConnect,onData,onTick,onClose} s w
	= serve
	{ Server
	| emptyServer
	& onInit          = \s w    ->
		({handlerResponse s & newConnection=[
			{ Connection
			| host     =host
			, port     =port
			, state    =""
			, onConnect=onConnectH
			, onError  = \e s w->(True, handlerResponse s, w)}]}, w)
	, onTick          = \s w    ->
		let (ms, r, w`) = onTick s w
		in ({HandlerResponse | liftHandler r & sendData=map (tuple "") (maybeToList ms)}, w`)
	, onClientClose   = \_ s w  ->
		let (s`, w`) = onClose s w
		in ({HandlerResponse | handlerResponse s` & stop=True}, w`)
	, onData          = \d _ s w->
		let (ms, r, w`) = onData d s w
		in (ms, "", liftHandler r, w`)
	} s w
where
	onConnectH ci s w
		# (ms, r, w) = onConnect s w
		= (ms, ci, liftHandler r, w)

liftHandler :: !*(ConnectionResponse .st) -> *(HandlerResponse ci .st)
liftHandler {ConnectionResponse | globalState,stop}
	= {HandlerResponse | handlerResponse globalState & stop=stop}

connectionResponse :: .st -> ConnectionResponse .st
connectionResponse s = {ConnectionResponse|globalState=s,stop=False}

emptyConnection :: ConnectionHandlers .st
emptyConnection
# { Server|idleTimeout,sendTimeout,connectTimeout} = emptyServer
= { ConnectionHandlers
	| idleTimeout   = idleTimeout
	, sendTimeout   = sendTimeout
	, connectTimeout= connectTimeout
	, onConnect     = \s w = (Nothing, connectionResponse s, w)
	, onData        = \_ s w = (Nothing, connectionResponse s, w)
	, onTick        = \s w = (Nothing, connectionResponse s, w)
	, onClose       = tuple
	}
