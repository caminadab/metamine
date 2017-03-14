require 'lua/util'

-- given a stream of http headers, parse each
function http_decode(input)
	local header = split(input, '\r\n\r\n')
	local lines = split(header, '\r\n')
	local first = lines[1]
	local info = split(first, ' ')
	local http = {}
	http.method = info[1]
	http.path = info[2]
	http.version = info[3]
	return http
end

-- given pages, encode the http stream
function http_encode(content)
	-- responses
	local header = append(
		'HTTP/1.1 200 OK\r\n',
		'Content-Length: ',
		totext(length(content)),
		'\r\n\r\n')
	local response = append(header, content)
	local stream = concat(response)
	return stream
end

local clients = magic()
clients.group = {'list', 'text'}
clients.val = {
	'GET / HTTP/1.1\r\nHost: localhost\r\n\r\nGET /zeg\r\nHost: hoi\r\n\r\n',
	'GET / HTTP/1.1\r\nHost: localhost\r\n\r\nGET /zeg\r\nHost: hoi\r\n\r\n',
}
local http = http_decode(clients)
local methods = { {'GET', 'GET'}, {'GET', 'GET' } }
local path = { {'/', '/zeg'}, {'/', '/zeg' } }
assert(methods[1][1] == 'GET' and methods[2][2] == 'GET')

local zeg = equals(http.path, '/zeg')
local fzeg = { {false, true}, {false, true} }
assert(fzeg[2][1] == false and fzeg[2][2] == true)
