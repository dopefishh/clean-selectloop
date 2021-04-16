module Echo

import StdEnv

import Data.Maybe
import Data.Tuple
import TCPServer.Listener

Start w = listen 8
	{ ListenerHandlers
	| emptyListener
	& onConnect     = \h p   s w->(?None, {emptyLConnection s & onData=onData}, listenerResponse (s+1), w)
	, onClose       = tuple
	} 0 w
where
	onData d c s w = (?Just d, c, listenerResponse s, w)
