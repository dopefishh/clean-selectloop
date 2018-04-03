implementation module TCPServer.HTTP

import TCPServer.Connection

import Control.Monad
import StdFunc
import Data.Func 
import Data.Functor
import Data.Tuple
import Data.Error
import Internet.HTTP

httpRequest :: .HTTPRequest !*World -> (MaybeErrorString HTTPResponse,.World)
httpRequest r w
= appFst (join o (fmap $ mb2error "Unparsable HTTPResponse" o parseResponse))
	$ connect r.server_name r.server_port
	{ emptyConnection
	& onConnect = \a w  ->(Just (toString r), connectionResponse a, w)
	, onData    = \d a w->(Nothing, connectionResponse (a +++ d), w)
	} "" w

Start w = httpRequest {newHTTPRequest & server_name="martlubbers.net", server_port=80, req_path="/"} w

/*httpServer port f w = serve
	{ idleTimeout = Just 50
	, sendTimeout     = Nothing
	, connectTimeout  = Nothing
	, onInit          = \s w    ->({handlerResponse s & newListener=[port]}, w)
	, onConnect       = \_ _ s w->(Nothing, "", handlerResponse s, w)
	, onNewSuccess    = \_ s w  ->(Nothing, "", handlerResponse s, w)
	, onTick          = \s w    ->(handlerResponse s, w)
	, onClientClose   = \_ s w  ->(handlerResponse s, w)
	, onListenerClose = \_ s w  ->(handlerResponse s, w)
	, onData          = \d a s w-> let na = a +++ d in
		case parseRequest na of
//			Nothing = (Nothing, na, handlerResponse s, w)
			/*Just */x = (Just $ f x, "", handlerResponse s, w)
	} () w

Start w = httpServer 8080 (\_->undef) w
*/
