implementation module TCPServer.HTTP

import Data.Error
import Data.Func 
import Data.List
import Data.Maybe
import Internet.HTTP
import StdEnv
import Text.URI

import TCPServer.Connection

httpRequest :: HTTPRequest !*World -> (MaybeErrorString HTTPResponse,*World)
httpRequest r w
	= case connect r.server_name r.server_port
			{ emptyConnection
			& onConnect = \a w  ->(?Just (toString r), connectionResponse a, w)
			, onData    = \d a w->(?None, connectionResponse (a +++ d), w)
			} "" w of
		(?Just e, _, w) = (Error e, w)
		(?None, d, w) = (mb2error "Unparsable HTTPResponse" $ parseResponse d, w)

httpRequestFollowRedirects :: HTTPRequest Int !*World -> (MaybeErrorString HTTPResponse,*World)
httpRequestFollowRedirects r 0 w = (Error "Maximum number of redirects reached", w)
httpRequestFollowRedirects r n w
	# (merr, w) = httpRequest r w
	| isError merr = (merr, w)
	# rsp = fromOk merr
	| not (isMember rsp.HTTPResponse.rsp_code [301, 302, 303, 307, 308]) = (merr, w)
	= case lookup "Location" rsp.HTTPResponse.rsp_headers of
		?None = (Error "Redirect but no Location header", w)
		?Just loc = case parseURI loc of
			?None = (Error "Redirect URI couldn't be parsed", w)
			?Just uri = httpRequestFollowRedirects
				{ r
				& server_name = fromMaybe loc uri.uriRegName
				, server_port = maybe 80 id uri.uriPort
				, req_path = uri.uriPath
				, req_query = maybe "" ((+++) "?") uri.uriQuery
				} (n-1) w
