module Echo

import StdEnv

import Data.Maybe
import Data.Tuple
import TCPServer.Listener

Start w = listen 8
	{ emptyListener
	& onConnect     = \h p   s w->(Nothing, s, listenerResponse (s+1), w)
	, onData        = \d   c s w->(Just d, c, listenerResponse s, w)
	, onClose       = tuple
	} 0 w
