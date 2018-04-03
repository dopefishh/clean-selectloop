module Echo

import StdEnv

import Data.Maybe
import Data.Tuple
import TCPServer.Listener

Start w = listen
	8123
	(Just 100)
	(Just 100)
	(Just 100)
	(\s w->(listenerResponse s, w))
	(\h p s w->(Nothing, s, listenerResponse (s+1), w))
	(\d c s w->(Just d, c, listenerResponse s, w))
	(\s w->(listenerResponse s, w))
	(\_ s w->(listenerResponse s, w))
	tuple
	0 w
