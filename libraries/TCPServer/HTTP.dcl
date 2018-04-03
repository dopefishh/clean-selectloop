definition module TCPServer.HTTP

from Internet.HTTP import :: HTTPRequest, :: HTTPResponse
from Data.Error import :: MaybeError, :: MaybeErrorString

httpRequest :: .HTTPRequest !*World -> (MaybeErrorString HTTPResponse,.World)

//httpServer :: Int (HTTPRequest st !*World -> (HTTPResponse, st, Bool)) st !*World -> (MaybeErrorString st, !*World)
