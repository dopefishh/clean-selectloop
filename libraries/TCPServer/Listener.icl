implementation module TCPServer.Listener

import TCPServer
import Data.Tuple
import Data.Maybe
import StdMisc

listen :: Int (ListenerHandlers ci .st) .st !*World -> *(Maybe String, .st, !*World) | == ci
listen port {ListenerHandlers|onInit,onConnect,onData,onTick,onClientClose,onClose} s w
	= serve
	{ Server
	| emptyServer
	& onInit        = \      s w->
		let (r, w`) = onInit s w
		in ({HandlerResponse | liftHandler r & newListener=[
			{ Listener
			| port=port
			, onConnect=onConnectH
			, onError  = \e s w->(True, handlerResponse s, w)
			}]}, w`)
	, onData        = \d   c s w->
		let (md, ci, r, w`) = onData d c s w
		in (md, ci, liftHandler r, w`)
	, onTick        = \      s w->
		let (r, w`) = onTick s w
		in (liftHandler r, w`)
	, onClientClose = \    c s w->
		let (r, w`) = onClientClose c s w
		in (liftHandler r, w`)
	, onClose       = onClose
	} s w
where
	onConnectH h p s w
		# (md, ci, r, w) = onConnect h p s w
		= (md,
			{ Connection
			| host     = h
			, port     = p
			, state    = ci
			, onError  = bail
			, onConnect= \c s w->(Nothing, c, handlerResponse s, w)
			, onClose  = \    c s w->
				let (r, w`) = onClientClose c s w
				in (liftHandler r, w`)
			}, liftHandler r, w)
	bail e s w = (True, handlerResponse s, w)

liftHandler {ListenerResponse|globalState,sendData,stop,closeConnection}
	= {HandlerResponse|handlerResponse globalState & sendData=sendData, stop=stop,closeConnection=closeConnection}

listenerResponse :: .st -> *(ListenerResponse ci .st)
listenerResponse s = {ListenerResponse|globalState=s,sendData=[],stop=False,closeConnection=[]}

emptyListener :: ListenerHandlers ci .st
emptyListener
# {Server|idleTimeout,sendTimeout,connectTimeout} = emptyServer
= { ListenerHandlers
	| idleTimeout   = idleTimeout
	, sendTimeout   = sendTimeout
	, connectTimeout= connectTimeout
	, onInit        = \    s w->(listenerResponse s, w)
	, onConnect     = \_ _ s w->(Nothing, undef, listenerResponse s, w)
	, onData        = \_ c s w->(Nothing, c, listenerResponse s, w)
	, onTick        = \    s w->(listenerResponse s, w)
	, onClientClose = \  c s w->(listenerResponse s, w)
	, onClose       = tuple
	}
