definition module TCPServer

from StdOverloaded import class ==
from StdMaybe import :: Maybe
from Data.Error import :: MaybeError, :: MaybeErrorString

from System.Time import :: Timespec

/* Server handlers
 * port      Port to listen to
 * timeout   Timeout to set the select to
 * timeout   Timeout to set the select to
 * onConnect The device with ip connected, you have to deliver a 
 *           local state and can update the global state
 * onClose   The device identified with ci is removed, you can update
 *           the state.
 *
 */
:: Server st ci =
	// Time between ticks when nothing happens in ms
	{ idleTimeout     :: Maybe Int
	// Send timeout in ms
	, sendTimeout     :: Maybe Int
	// Connect timeout in ms
	, connectTimeout  :: Maybe Int
	//Runs initially
	, onInit          ::               st *World -> *(*(HandlerResponse st ci), !*World)
	//Runs when a client connects to one of your listeners
	, onConnect       :: String Int    st *World -> *(Maybe String, ci, *(HandlerResponse st ci), !*World)
	//Runs when a new connection was set up successfully
	, onNewSuccess    ::            ci st *World -> *(Maybe String, ci, *(HandlerResponse st ci), !*World)
	//Runs when there is data on one of the channels
	, onData          :: String     ci st *World -> *(Maybe String, ci, *(HandlerResponse st ci), !*World)
	//Runs when the select timer times out
	, onTick          ::               st *World -> *(*(HandlerResponse st ci), !*World)
	//Runs when a client closes the connection or when you close a channel connection
	, onClientClose   ::            ci st *World -> *(*(HandlerResponse st ci), !*World)
	//Runs when you close a listener
	, onListenerClose ::        Int    st *World -> *(*(HandlerResponse st ci), !*World)
	//Runs when you close
	, onClose         ::               st *World -> *(st, !*World)
	}

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
emptyServer :: Server st ci

:: Connection
	= Listener Int
	| Connection Int String

serve :: !.(Server .a b) .a !*World -> (MaybeError String .a, !*World) | == b
