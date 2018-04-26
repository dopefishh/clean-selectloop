definition module TCPServer

from StdOverloaded import class ==
from StdMaybe import :: Maybe
from Data.Error import :: MaybeError, :: MaybeErrorString

from System.Time import :: Timespec

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
	, onTick          ::                    st -> *(*World -> *(*(HandlerResponse ci st), !*World))
	//* Runs when the select timer times out
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

/**
 * Possible TCPServer errors
 */
:: TCPServerError
	= ConnectionTimedOut
	| ConnectionLookupError
	| ConnectionUnableToOpen
	| ListenerUnableToOpen
	| ListenerUnableToAnswer

/**
 * Listener object
 *
 * @var Client state
 * @var Global state
 */
:: Listener ci st =
	{ port      :: Int
	//* Port of the listener
	, onConnect :: String Int -> .(st -> *(*World -> *(Maybe String, Connection ci st, *(HandlerResponse ci st), !*World)))
	//* Runs for every client that connects
	, onClose   :: st -> *(*World -> *(*(HandlerResponse ci st), !*World))
	//* Runs when the listener is closed again
	, onError   :: TCPServerError -> .(st -> *(*World -> *(Bool, *(HandlerResponse ci st), !*World)))
	//* Runs if an error occurred, if the flag is set, the server will lift the error to a global error
	} 

/**
 * Creates a stub Connection object
 *
 * @param hostname
 * @param port
 * @param initial client state
 * @result Connection
 */
emptyListener :: Int -> Listener ci .st

/**
 * Connection object
 *
 * @var Client state
 * @var Global state
 */
:: Connection ci st =
	{ host      :: String
	//* Host of the connection
	, port      :: Int
	//* Port of the connection
	, state     :: ci
	//* Client state
	, onConnect :: ci -> .(st -> *(*World -> *(Maybe String, ci, *(HandlerResponse ci st), !*World)))
	//* Runs on connection
	, onData    :: String ci -> .(st -> *(*World -> *(Maybe String, ci, *(HandlerResponse ci st), !*World)))
	//* Runs when data is received
	, onClose   :: ci -> .(st -> *(*World -> *(*(HandlerResponse ci st), !*World)))
	//* Runs on close
	, onError   :: TCPServerError -> .(st -> *(*World -> *(Bool, *(HandlerResponse ci st), !*World)))
	//* Runs when the connection throws an error
	}

/**
 * Creates a stub Connection object
 *
 * @param hostname
 * @param port
 * @param initial client state
 * @result Connection
 */
emptyConnection :: String Int ci -> Connection ci .st

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
