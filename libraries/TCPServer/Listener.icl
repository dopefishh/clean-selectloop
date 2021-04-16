implementation module TCPServer.Listener

import Data.Tuple
import StdEnv

import TCPServer

emptyLConnection :: ci -> LConnection ci .st
emptyLConnection st =
	{ LConnection
	| state = st
	, port  = 0
	, onConnect = \c s w->(?None, c, listenerResponse s, w)
	, onData    = \d c s w->(?None, c, listenerResponse s, w)
	, onClose   = \c s w->(listenerResponse s, w)
	}

listen :: Int (ListenerHandlers ci .st) .st !*World -> *(? String, .st, !*World) | == ci
listen port {ListenerHandlers|onInit,onConnect,onTick,onClose} s w
	= serve
	{ Server
	| emptyServer
	& onInit        = \      s w->
		let (r, w`) = onInit s w
		in ({HandlerResponse | liftHandler r & newListener=[
			{ Listener
			| port=port
			, onConnect=onConnectH
			, onClose  = \s w  ->(handlerResponse s, w)
			, onError  = \e s w->(True, handlerResponse s, w)
			}]}, w`)
	, onTick        = \      s w->
		let (r, w`) = onTick s w
		in (liftHandler r, w`)
	, onClose       = onClose
	} s w
where
	onConnectH h p s w
		# (md, crecord, r, w) = onConnect h p s w
		= (md,
			{ Connection
			| host     = h
			, port     = p
			, state    = crecord.LConnection.state
			, onError  = bail
			, onConnect= \c s w->
				let (md, cs, r, w`) = crecord.LConnection.onConnect c s w
				in (md, cs, liftHandler r, w`)
			, onClose  = \    c s w->
				let (r, w`) = crecord.LConnection.onClose c s w
				in (liftHandler r, w`)
			, onData   = \d c s w->
				let (md, cs, r, w`) = crecord.LConnection.onData d c s w
				in (md, cs, liftHandler r, w`)
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
	, onConnect     = \_ _ s w->(?None, undef, listenerResponse s, w)
	, onTick        = \    s w->(listenerResponse s, w)
	, onClose       = tuple
	}
