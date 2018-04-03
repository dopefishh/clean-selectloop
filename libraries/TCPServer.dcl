definition module TCPServer

from StdOverloaded import class ==
from StdMaybe import :: Maybe

from System.Time import :: Timespec

:: *HandlerResponse st ci =
	{ globalState     :: st
	, newListener     :: [Int]
	, newConnection   :: [(String, Int, ci)]
	, sendData        :: [(ci, String)]
	, closeListener   :: [Int]
	, closeConnection :: [ci]
	, stop            :: Bool
	}

handlerResponse :: .st -> *(HandlerResponse .st ci)

:: Connection
	= Listener Int
	| Connection Int String

serve ::
	(Maybe Int) //idleTimeout
	(Maybe Int) //sendTimeout
	(Maybe Int) //connectTimeout
	(.st -> .(*World -> *(*(HandlerResponse .st ci), !*World))) //onInit
	(String Int -> .(.st -> .(*World -> *(Maybe String, ci, *(HandlerResponse .st ci), !*World)))) //onConnect
	(ci -> .(.st -> .(*World -> *(Maybe String, ci, *(HandlerResponse .st ci), !*World)))) //onNewSuccess
	(String ci -> .(.st -> .(*World -> *(Maybe String, ci, *(HandlerResponse .st ci), !*World)))) //onData
	(.st -> .(*World -> *(*(HandlerResponse .st ci), !*World))) //onTick
	(ci -> .(.st -> .(*World -> *(*(HandlerResponse .st ci), !*World)))) //onClientClose
	(Int -> .(.st -> .(*World -> *(*(HandlerResponse .st ci), !*World)))) //onListenerClose
	(.st -> .(*World -> *(.st, !*World))) // onClose
	.st //initial state
	!*World
	-> (Maybe String, .st, !*World)
	| == ci
