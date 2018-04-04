definition module TCPServer.Listener

from StdOverloaded import class ==
from Data.Maybe import :: Maybe
from Data.Error import :: MaybeError, :: MaybeErrorString

listen :: Int (ListenerHandlers ci .st) .st !*World -> *(Maybe String, .st, !*World) | == ci

:: ListenerHandlers ci st =
	{ idleTimeout     :: Maybe Int
	, sendTimeout     :: Maybe Int
	, connectTimeout  :: Maybe Int
	, onInit          ::                    st -> *(*World -> *(                  *(ListenerResponse ci st), !*World))
	, onConnect       :: String Int    -> .(st -> *(*World -> *(Maybe String, ci, *(ListenerResponse ci st), !*World)))
	, onData          :: String     ci -> .(st -> *(*World -> *(Maybe String, ci, *(ListenerResponse ci st), !*World)))
	, onTick          ::                    st -> *(*World -> *(                  *(ListenerResponse ci st), !*World))
	, onClientClose   ::            ci -> .(st -> *(*World -> *(                  *(ListenerResponse ci st), !*World)))
	, onClose         ::                    st -> *(*World -> *(st, !*World))
	}

:: *ListenerResponse ci st =
	{ globalState     :: st
	, sendData        :: .[.(ci, String)]
	, closeConnection :: .[ci]
	, stop            :: Bool
	}

listenerResponse :: .st -> *(ListenerResponse ci .st)
emptyListener :: ListenerHandlers ci .st
