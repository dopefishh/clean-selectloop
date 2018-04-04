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
	, onConnect       :: String Int    -> .(st -> *(*World -> *(Maybe String, ci, *(HandlerResponse ci st), !*World)))
	//* Runs when a client connects to one of your listeners
	, onNewSuccess    ::            ci -> .(st -> *(*World -> *(Maybe String, ci, *(HandlerResponse ci st), !*World)))
	//* Runs when a new connection was set up successfully
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
	{ globalState     :: st
	//* State
	, newListener     :: [Int]
	//* Listeners to add
	, newConnection   :: [(String, Int, ci)]
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
serve :: (Server ci .st) .st !*World -> *(Maybe String, .st, !*World) | == ci

/**
 * Create a HandlerResponse from a given state
 *
 * @param State
 * @result Handleresponse
 */
handlerResponse :: .st -> *(HandlerResponse ci .st)

/**
 * Create an empty server
 *
 * @result A Server record
 */
emptyServer :: Server ci .st
