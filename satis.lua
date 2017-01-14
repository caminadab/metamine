a = enchant('1,2')
b = split(s, ',')
c = b[3]

-- modify!
a.val = '1,2,3'
trigger(a)

--[[srv = server(10101)

cli = client('127.0.0.1:10101')
cli.output = 'GET / HTTP/1.1\r\nHost: localhost\r\n\r\n'

-- parse headers
input = srv.clients.input
header = split(input, '\r\n\r\n')
lines = split(header, '\r\n')
first = split(lines[1], ' ')]]
--path = first[2]

-- page
--[[content = 'hoi'

-- responses
respline = 'HTTP/1.1 200 OK\r\n'
resplength = 'Content-Length: ' .. #content .. '\r\n'
respempty = '\r\n'
respheader = respline .. resplength .. respempty

responses = respheader .. respbody
cli.output = responses
]]