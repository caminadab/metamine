a = enchant('Makefile satis.lua')
b = split(a, ' ')
c = infile(b)

srv = server(10101)
input = srv.clients.input
output = srv.clients.output

-- example
cli = client('127.0.0.1:10101')
cli.output = 'GET /index.html HTTP/1.1\r\nHost: localhost\r\n\r\n'

-- parse headers
header = split(input, '\r\n\r\n')
lines2 = split(header, '\r\n')
intro = lines2[1]
mpv = split(intro, ' ')
method = mpv[1]
path = mpv[2]
version = mpv[3]

-- page
wwwpath = prepend(path, 'www')
content = infile(wwwpath)

-- responses
header1 = 'HTTP/1.1 200 OK\r\nContent-Length: '
len = totext(length(content))
header2 = prepend(len, header1)
header = append(header2, '\r\n\r\n')

response = concat1(header, content)

--responses = respheader .. respbody
--cli.output = responses