require 'sas/http'

srv = server(10101)
http_in = http_decode(srv.clients.input)
zeg = where(http_in.data, equals(http_in.path, '/zeg'))

content = infile(append('www', http_in.path))
http_out = http_encode(content)
srv.clients.output = http_out

-- test
local req = 'POST /say\r\nHost: hoi\r\n\r\n'
cli = client('localhost:10101')
cli.output = enchant(req)
