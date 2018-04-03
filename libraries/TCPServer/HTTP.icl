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
= case connect
		r.server_name
		r.server_port
		(Just 100)
		(Just 100)
		(Just 100)
		(\a w  ->(Just (toString r), connectionResponse a, w))
		(\d a w->(Nothing, connectionResponse (a +++ d), w))
		(\a w->(Nothing, connectionResponse a, w))
		tuple
		""
		w of
	(Just e, _, w) = (Error e, w)
	(_, acc, w) = (mb2error "Unparsable HTTPResponse" $ parseResponse acc, w)

//httpServer :: Int (HTTPRequest st !*World -> (HTTPResponse, st, Bool)) st !*World -> (MaybeErrorString st, !*World)
//httpServer port fun st w = listen port
//	{ emptyListener
//	| onConnect = onConnect 
//	} st w
//where
//	onConnect host port st w
//		= (Just "", (), listenerResponse st, w)
