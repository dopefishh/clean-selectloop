module Daytime

import StdEnv

import System.Time
import Data.Maybe
import Data.Tuple
import TCPServer.Listener

Start w = listen
	8123
	(Just 100)
	(Just 100)
	(Just 100)
	(\s w->(listenerResponse s, w))
	(\h p s w->let (t, w`) = time w in (Just (toString t +++ "\n"), s, listenerResponse s, w`))
	(\_ c s w->(Nothing, c, listenerResponse s, w))
	(\s w->(listenerResponse s, w))
	(\_ s w->(listenerResponse s, w))
	tuple
	"" w
