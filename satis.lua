-- start webserver
srv = server(10101)

-- parse headers
header = split(srv.clients.input, '\r\n\r\n')
lines = split(header, '\r\n')
intro = lines[1]
mpv = split(intro, ' ')
method,path,version = mpv[1],mpv[2],mpv[3]

-- page
wwwpath = append('www', path)
content = infile(wwwpath)

-- responses
rheader = append(
	'HTTP/1.1 200 OK\r\n',
	'Content-Length: ',
	totext(length(content)),
	'\r\n\r\n')
response = append(rheader, content)
stream = concat(response)

srv.clients.output = stream

-- self test
cli = client('127.0.0.1:10101')
cli.output = enchant('GET /index.html HTTP/1.1\r\nHost: localhost\r\n\r\n')
