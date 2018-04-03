implementation module TCPServer.Connection

import StdEnv
import TCPServer
import Data.Maybe
import Data.Tuple
import Data.Error

connect ::
	String //Host
	Int //Port
	(Maybe Int) //idleTimeout
	(Maybe Int) //sendTimeout
	(Maybe Int) //connectTimeout
	(.st -> .(*World -> *(Maybe String, *(ConnectionResponse .st), !*World))) //onConnect
	(String -> .(.st -> .(*World -> *(Maybe String, *(ConnectionResponse .st), !*World)))) //onData
	(.st -> .(*World -> *(Maybe String, *(ConnectionResponse .st), !*World))) // onTick
	(.st -> .(*World -> *(.st, !*World))) // onClose
	.st
	!*World
	-> *(Maybe String, .st, !*World)
connect host port idleTimeout sendTimeout connectTimeout onConnect onData onTick onClose s w
	= serve
	idleTimeout sendTimeout connectTimeout 
	(\s w->({handlerResponse s & newConnection=[(host, port, "")]}, w)) //onInit
	(\_ _ s w->(Nothing, undef, handlerResponse s, w))
	(\_ s w  ->let (ms, r, w`) = onConnect s w in (ms, "", liftHandler r, w`)) //onNewSuccess
	(\d _ s w->let (ms, r, w`) = onData d s w in (ms, "", liftHandler r, w`)) //onData
	(\s w->let (ms, r, w`) = onTick s w in ({HandlerResponse | liftHandler r & sendData=map (tuple "") (maybeToList ms)}, w`)) //onTick
	(\_ s w->let (s`, w`) = onClose s w in ({HandlerResponse | handlerResponse s` & stop=True}, w`)) //onClientClose
	(\_ s w->(handlerResponse s, w)) //onListenerClose
	tuple
	s
	w

liftHandler :: !*(ConnectionResponse .a) -> *(HandlerResponse .a b)
liftHandler {ConnectionResponse | globalState,stop}
	= {HandlerResponse | handlerResponse globalState & stop=stop}

connectionResponse :: st -> ConnectionResponse st
connectionResponse s = {ConnectionResponse|globalState=s,stop=False}
