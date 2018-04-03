definition module TCPServer.Listener

from StdOverloaded import class ==
from Data.Maybe import :: Maybe

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
	(.st -> .(*World -> *(.st, !*World))) //onClose
	.st //initial state
	!*World
	-> *(Maybe String, .st, !*World) | == ci

:: *ListenerResponse st ci =
	{ globalState     :: st
	, sendData        :: [(ci, String)]
	, closeConnection :: [ci]
	, stop            :: Bool
	}

listenerResponse :: st -> ListenerResponse st ci
