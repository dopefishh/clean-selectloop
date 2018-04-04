definition module TCPServer.Connection

from Data.Maybe import :: Maybe
from Data.Error import :: MaybeError, :: MaybeErrorString

/*
 * Connection handlers
 *
 * @var State
 */
:: ConnectionHandlers st =
	{ idleTimeout     :: Maybe Int
	//* Time between ticks when nothing happens in ms
	, sendTimeout     :: Maybe Int
	//* Send timeout in ms
	, connectTimeout  :: Maybe Int
	//* Connect timeout in ms
	, onConnect       ::             st -> *(*World -> *(Maybe String, *(ConnectionResponse st), !*World))
	//* Runs after the connection has been established
	, onData          :: String -> .(st -> *(*World -> *(Maybe String, *(ConnectionResponse st), !*World)))
	//* Runs when there is data
	, onTick          ::             st -> *(*World -> *(Maybe String, *(ConnectionResponse st), !*World))
	//* Runs when the select timer times out
	, onClose         ::             st -> *(*World -> *(st, !*World))
	//* Runs when you close
	}

/*
 * Connection response
 *
 * @var State
 */
:: *ConnectionResponse st =
	{ globalState :: st
	//* State
	, stop        :: Bool
	//* Stop
	}

/*
 * The connect function
 * This is an abstraction over {{TCPServer}}'s {{serve}}.
 * In this abstraction there is only one connection.
 *
 * @param Hostname
 * @param Port
 * @param Handlers
 * @param Initial state
 * @param World
 * @result Maybe an error message, the state and the world
 */
connect :: String Int (ConnectionHandlers .st) .st !*World -> *(Maybe String, .st, !*World)

/*
 * Create a ConnectionResponse form a given state
 *
 * @param State
 * @result Connection response
 */
connectionResponse :: .st -> ConnectionResponse .st

/*
 * Create an empty connection
 *
 * @result Connection record
 */
emptyConnection :: ConnectionHandlers .st
