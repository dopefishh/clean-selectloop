definition module TCPServer.Connection

from Data.Maybe import :: Maybe
from Data.Error import :: MaybeError, :: MaybeErrorString

connect :: String Int (ConnectionHandlers st) st !*World -> *(MaybeErrorString st, !*World)

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
emptyConnection :: ConnectionHandlers st
