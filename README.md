# Clean select loop

Write network applications in a reactive way in clean

### Libraries

- TCPServer

	Contains the master function `serve`.
- TCPServer.Listener

	Contains an abstraction over `serve` only handling the listening part.
- TCPServer.Connection

	Contains an abstraction over `serve` only handling one tcp connection to a
	server.
- TCPServer.HTTP

	Contains an abstraction over `TCPServer.Connection` that can send one
	`HTTPRequest`.

### Examples

- Daytime

	Implements the `RFC 867` tcp based daytime service
- Echo

	Implements the `RFC 862` tcp based echo service
- Wget

	Implements a simple http file downloader
- IRC

	Implements a simple IRC bot interface (todo)
