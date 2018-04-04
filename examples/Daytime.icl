module Daytime

import StdEnv

import System.Time
import Data.Maybe
import Data.Tuple
import TCPServer.Listener

Start w
# (io, w) = stdio w
# (merr, io, w) = listen 8123
	{ emptyListener
	& onConnect     = \h p   s w->
		let (t, w`) = time w
		in (Just (toString t +++ "\n"), 0, listenerResponse s, w`)
	} io w
= fclose io w
