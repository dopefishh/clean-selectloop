definition module TCPServer.Connection

from Data.Maybe import :: Maybe

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

:: ConnectionHandlers st =
	{ idleTimeout     :: Maybe Int
	, sendTimeout     :: Maybe Int
	, connectTimeout  :: Maybe Int
	, onConnect       ::        st *World -> *(Maybe String, *(ConnectionResponse st), !*World)
	, onData          :: String st *World -> *(Maybe String, *(ConnectionResponse st), !*World)
	, onTick          ::        st *World -> *(Maybe String, *(ConnectionResponse st), !*World)
	, onClose         ::        st *World -> *(st, !*World)
	}

:: *ConnectionResponse st =
	{ globalState :: st
	, stop        :: Bool
	}

connectionResponse :: st -> ConnectionResponse st
