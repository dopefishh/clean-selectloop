module Wget

import StdEnv

import System.GetOpt
import System.CommandLine
import Data.Maybe
import Data.Error
import Text.URI
import Internet.HTTP

import TCPServer.HTTP

exit i e w
# (io, w) = stdio w
= snd (fclose (io <<< e <<< "\n") (setReturnCode i w))

die :== exit 1

Start w
# ([argv0:args], w) = getCommandLine w
| args =: [] || args =: [_,_:_] = die ("usage: " +++ argv0 +++ " URL\n") w
= case parseURI (hd args) of
	Nothing = die "Unable to parse URI" w
	Just uri = case httpRequestFollowRedirects
			{ newHTTPRequest
			& server_name = fromMaybe ""  uri.uriRegName
			, server_port = fromMaybe 80  uri.uriPort
			, req_path    = if (uri.uriPath == "") "/" uri.uriPath
			, req_query   = fromMaybe ""  uri.uriQuery
			} 10 w of
		(Error e, w) = die e w
		(Ok resp, w) = exit 0 resp.rsp_data w
