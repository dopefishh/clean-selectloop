definition module TCPServer.Listener

from StdOverloaded import class ==
from Data.Maybe import :: Maybe
from Data.Error import :: MaybeError, :: MaybeErrorString

listen :: Int (ListenerHandlers ci st) st !*World -> *(MaybeErrorString st, !*World) | == ci

:: ListenerHandlers ci st =
	{ idleTimeout     :: Maybe Int
	, sendTimeout     :: Maybe Int
	, connectTimeout  :: Maybe Int
	, onInit          ::               st *World -> *(                  *(ListenerResponse st ci), !*World)
	, onConnect       :: String Int    st *World -> *(Maybe String, ci, *(ListenerResponse st ci), !*World)
	, onData          :: String     ci st *World -> *(Maybe String, ci, *(ListenerResponse st ci), !*World)
	, onTick          ::               st *World -> *(                  *(ListenerResponse st ci), !*World)
	, onClientClose   ::            ci st *World -> *(                  *(ListenerResponse st ci), !*World)
	, onClose         ::               st *World -> *(st, !*World)
	}

:: *ListenerResponse st ci =
	{ globalState     :: st
	, sendData        :: [(ci, String)]
	, closeConnection :: [ci]
	, stop            :: Bool
	}

listenerResponse :: st -> ListenerResponse st ci
emptyListener :: ListenerHandlers ci st
