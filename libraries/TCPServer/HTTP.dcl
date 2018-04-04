definition module TCPServer.HTTP

from Internet.HTTP import :: HTTPRequest, :: HTTPResponse
from Data.Error import :: MaybeError, :: MaybeErrorString

/*
 * Do a HTTP request
 *
 * @param The request
 * @param The world
 * @result Maybe an error or a HTTPResponse and the world
 */
httpRequest :: HTTPRequest !*World -> (MaybeErrorString HTTPResponse,*World)

/*
 * Do a HTTP request and follow redirect responses
 *
 * @param The request
 * @param The maximum number of redirects it will follow
 * @param The world
 * @result Maybe an error or a HTTPResponse and the world
 */
httpRequestFollowRedirects :: HTTPRequest Int !*World -> (MaybeErrorString HTTPResponse,*World)
