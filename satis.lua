-- start webserver
srv = server(10101)

-- parse headers
http = {}
http.clis = srv.clients
http.header = split(http.clis.input, '\r\n\r\n')
http.lines = split(http.header, '\r\n')
http.intro = http.lines[1]
http.mpv = split(http.intro, ' ')
http.method = http.mpv[1]
http.path = http.mpv[2]
http.version = http.mpv[3]

-- page
http.wwwpath = prepend1(http.path, 'www')
http.content = infile(http.wwwpath)

-- responses
http.rheaderA = 'HTTP/1.1 200 OK\r\nContent-Length: '
http.rlen = totext(length(http.content))
http.rheaderB = prepend1(http.rlen, http.rheaderA)
http.rheader = append1(http.rheaderB, '\r\n\r\n')

http.response = append(http.rheader, http.content)
http.stream = concat(http.response)

http.clis.output = http.stream

-- self test
cli = client('127.0.0.1:10101')
cli.output = enchant('GET /index.html HTTP/1.1\r\nHost: localhost\r\n\r\n')
