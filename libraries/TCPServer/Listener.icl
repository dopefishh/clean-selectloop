implementation module TCPServer.Listener

import TCPServer
import Data.Tuple
import Data.Maybe

listen ::
	Int //port
	(Maybe Int) //idleTimeout
	(Maybe Int) //sendTimeout
	(Maybe Int) //connectTimeout
	(.st -> .(*World -> *(*(ListenerResponse .st ci), !*World))) // onInit
	(String Int -> .(.st -> .(*World -> *(Maybe String, ci, *(ListenerResponse .st ci), !*World)))) // onConnect
	(String ci -> .(.st -> .(*World -> *(Maybe String, ci, *(ListenerResponse .st ci), !*World)))) // onData
	(.st -> .(*World -> *(*(ListenerResponse .st ci), !*World))) // onTick
	(ci -> .(.st -> .(*World -> *(*(ListenerResponse .st ci), !*World)))) // onClientClose
	(.st -> .(*World -> *(.st, !*World)))
	.st
	!*World
	-> *(Maybe String, .st, !*World) | == ci
listen port idleTimeout sendTimeout connectTimeout onInit onConnect onData onTick onClientClose onClose s w
	= serve
		idleTimeout sendTimeout connectTimeout
		(\s w->let (r, w`) = onInit s w in ({HandlerResponse | liftHandler r & newListener=[port]}, w`)) //onInit
		(\h p s w->let (md, ci, r, w`) = onConnect h p s w in (md, ci, liftHandler r, w`)) //onConnect
		(\c s w->(Nothing, c, handlerResponse s, w)) //onNewSuccess
		(\d c s w->let (md, ci, r, w`) = onData d c s w in (md, ci, liftHandler r, w`)) //onData
		(\s w->let (r, w`) = onTick s w in (liftHandler r, w`)) //onTick
		(\c s w->let (r, w`) = onClientClose c s w in (liftHandler r, w`)) //onClientClose
		(\_ s w->(handlerResponse s, w)) //onListenerClose
		onClose
		s w

liftHandler {ListenerResponse|globalState,sendData,stop,closeConnection}
	= {HandlerResponse|handlerResponse globalState & sendData=sendData, stop=stop,closeConnection=closeConnection}

listenerResponse :: st -> ListenerResponse st ci
listenerResponse s = {ListenerResponse|globalState=s,sendData=[],stop=False,closeConnection=[]}
