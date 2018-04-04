implementation module TCPServer.Listener

import TCPServer
import Data.Tuple
import Data.Maybe
import StdMisc

listen :: Int (ListenerHandlers ci st) st !*World -> *(MaybeErrorString st, !*World) | == ci
listen port {ListenerHandlers|onInit,onConnect,onData,onTick,onClientClose,onClose} s w
	= serve
	{ Server
	| emptyServer
	& onInit        = \      s w->
		let (r, w`) = onInit s w
		in ({HandlerResponse | liftHandler r & newListener=[port]}, w`)
	, onConnect     = \h p   s w->
		let (md, ci, r, w`) = onConnect h p s w
		in (md, ci, liftHandler r, w`)
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

liftHandler {ListenerResponse|globalState,sendData,stop,closeConnection}
	= {HandlerResponse|handlerResponse globalState & sendData=sendData, stop=stop,closeConnection=closeConnection}

listenerResponse :: st -> ListenerResponse st ci
listenerResponse s = {ListenerResponse|globalState=s,sendData=[],stop=False,closeConnection=[]}

emptyListener :: ListenerHandlers ci st
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
