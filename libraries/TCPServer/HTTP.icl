implementation module TCPServer.HTTP

import TCPServer.Connection

import Control.Monad
import StdFunc
import Data.Func 
import Data.Functor
import Data.Tuple
import Data.Error
import Internet.HTTP

httpRequest :: HTTPRequest !*World -> (MaybeErrorString HTTPResponse,*World)
httpRequest r w
	= case connect r.server_name r.server_port
			{ emptyConnection
			& onConnect = \a w  ->(Just (toString r), connectionResponse a, w)
			, onData    = \d a w->(Nothing, connectionResponse (a +++ d), w)
			} "" w of
		(Just e, _, w) = (Error e, w)
		(Nothing, d, w) = (mb2error "Unparsable HTTPResponse" $ parseResponse d, w)
