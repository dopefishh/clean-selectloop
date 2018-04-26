definition module TCPServer.Listener

from StdOverloaded import class ==
from Data.Maybe import :: Maybe
from Data.Error import :: MaybeError, :: MaybeErrorString

/***
 * The listener handlers.
 *
 * @var Client state
 * @var Global state
 */
:: ListenerHandlers ci st =
	{ idleTimeout     :: Maybe Int
	//* Time between ticks when nothing happens in ms
	, sendTimeout     :: Maybe Int
	//* Send timeout in ms
	, connectTimeout  :: Maybe Int
	//* Connect timeout in ms
	, onInit          ::                    st -> *(*World -> *(                  *(ListenerResponse ci st), !*World))
	//* Runs initially
	, onConnect       :: String Int    -> .(st -> *(*World -> *(Maybe String, LConnection ci st, *(ListenerResponse ci st), !*World)))
	//* Runs when there is data from one of the clients
	, onTick          ::                    st -> *(*World -> *(                  *(ListenerResponse ci st), !*World))
	//* Runs when the select timer times out
	, onClose         ::                    st -> *(*World -> *(st, !*World))
	//* Runs when you close
	}

/***
 * Listener response
 *
 * @var Client state
 * @var Global state
 */
:: *ListenerResponse ci st =
	{ globalState     :: st
	, sendData        :: [(ci, String)]
	, closeConnection :: [ci]
	, stop            :: Bool
	}

/***
 * Connection object
 *
 * @var Client state
 * @var Global state
 */
:: LConnection ci st =
	{ state     :: ci
	// Client state
	, port      :: Int
	// Port
	, onConnect :: ci -> .(st -> *(*World -> *(Maybe String, ci, *(ListenerResponse ci st), !*World)))
	// Runs when the client is connected
	, onData    :: String ci -> .(st -> *(*World -> *(Maybe String, ci, *(ListenerResponse ci st), !*World)))
	// Runs when data is received
	, onClose   :: ci -> .(st -> *(*World -> *(*(ListenerResponse ci st), !*World)))
	// Runs when the client is closed
	}

/**
 * Creates a stub Connection
 *
 * @param initial state
 * @result LConnection
 */
emptyLConnection :: ci -> LConnection ci .st

/***
 * The listen function
 * This is an abstraction over {{TCPServer}}'s {{serve}}.
 * In this abstraction there is only one listener.
 *
 * @param The port to listen on
 * @param Handlers
 * @param Initial state
 * @param World
 * @result Maybe an error message, the state and the world
 */
listen :: Int (ListenerHandlers ci .st) .st !*World -> *(Maybe String, .st, !*World) | == ci

/***
 * Create a ListenerResponse from a given state
 *
 * @param State
 * @result ListenerResponse
 */
listenerResponse :: .st -> *(ListenerResponse ci .st)

/***
 * Create an empty listener
 *
 * @result A Listener record
 */
emptyListener :: ListenerHandlers ci .st
