definition module TCPServer

from StdOverloaded import class ==
from StdMaybe import :: Maybe
from Data.Error import :: MaybeError, :: MaybeErrorString

from System.Time import :: Timespec

:: OnDataFun ci st :== String ci -> .(st -> *(*World -> *(Maybe String, ci, *(HandlerResponse ci st), !*World)))

/**
 * The server handlers
 *
 * @var Client state
 * @var Global state
 */
:: Server ci st =
	{ idleTimeout     :: Maybe Int
	//* Time between ticks when nothing happens in ms
	, sendTimeout     :: Maybe Int
	//* Send timeout in ms
	, connectTimeout  :: Maybe Int
	//* Connect timeout in ms
	, onInit          ::                    st -> *(*World -> *(*(HandlerResponse ci st), !*World))
	//* Runs initially
	, onData          :: String     ci -> .(st -> *(*World -> *(Maybe String, ci, *(HandlerResponse ci st), !*World)))
	//* Runs when there is data on one of the channels
	, onTick          ::                    st -> *(*World -> *(*(HandlerResponse ci st), !*World))
	//* Runs when the select timer times out
	, onClientClose   ::            ci -> .(st -> *(*World -> *(*(HandlerResponse ci st), !*World)))
	//* Runs when a client closes the connection or when you close a channel connection
	, onListenerClose ::        Int    -> .(st -> *(*World -> *(*(HandlerResponse ci st), !*World)))
	//* Runs when you close a listener
	, onClose         ::                    st -> *(*World -> *(st, !*World))
	//* Runs when you close
	}

/**
 * Handler response
 *
 * @var Client state
 * @var Global state
 */
:: *HandlerResponse ci st =
	{ globalState     :: !st
	//* State
	, newListener     :: [Listener ci st]
	//* Listeners to add, Listeners are a port and a handler
	, newConnection   :: [Connection ci st]
	//* Connections to add, host, port and initial state
	, sendData        :: [(ci, String)]
	//* Data to send, relies on == of ci
	, closeListener   :: [Int]
	//* Listeners to close by port
	, closeConnection :: [ci]
	//* Connections to close by ci
	, stop            :: Bool
	//* Stop
	}

:: Listener ci st =
	{ port      :: Int
	, onConnect :: String Int -> .(st -> *(*World -> *(Maybe String, Connection ci st, *(HandlerResponse ci st), !*World)))
	, onError   :: TCPServerError -> .(st -> *(*World -> *(Bool, *(HandlerResponse ci st), !*World)))
	} 

:: TCPServerError
	= ConnectionTimedOut
	| ConnectionLookupError
	| ConnectionUnableToOpen
	| ListenerUnableToOpen
	| ListenerUnableToAnswer

:: Connection ci st =
	{ host      :: String
	, port      :: Int
	, state     :: ci
	, onConnect :: ci -> .(st -> *(*World -> *(Maybe String, ci, *(HandlerResponse ci st), !*World)))
	, onClose   :: ci -> .(st -> *(*World -> *(*(HandlerResponse ci st), !*World)))
	, onError   :: TCPServerError -> .(st -> *(*World -> *(Bool, *(HandlerResponse ci st), !*World)))
	}

/**
 * The serve function.
 * With this function you can create a dynamic system of TCP connections.
 * In every handler you have access to a possibly unique state.
 * With every client interaction you have access to a client state.
 *
 * @param Handlers
 * @param Initial state
 * @param World
 * @result Maybe an error message, the state and the world
 */
serve :: (Server ci .st) .st !*World -> *(Maybe String, !.st, !*World) | == ci

/**
 * Create a HandlerResponse from a given state
 *
 * @param State
 * @result Handleresponse
 */
handlerResponse :: !.st -> *(HandlerResponse ci .st)

/**
 * Create an empty server
 *
 * @result A Server record
 */
emptyServer :: Server ci .st
