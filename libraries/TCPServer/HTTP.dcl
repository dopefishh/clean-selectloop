definition module TCPServer.HTTP

from Internet.HTTP import :: HTTPRequest, :: HTTPResponse
from Data.Error import :: MaybeError, :: MaybeErrorString

httpRequest :: HTTPRequest !*World -> (MaybeErrorString HTTPResponse,*World)

httpRequestFollowRedirects :: HTTPRequest Int !*World -> (MaybeErrorString HTTPResponse,*World)
