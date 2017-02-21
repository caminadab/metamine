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

srv = server(10101)
http_in = http_decode(srv.clients.input)
-- {client->[text]}
content = infile(append('www', http_in.path))
counter = totext(sum(count(content)))
http_out = http_encode(append(content,'geserveert: ',counter))
srv.clients.output = http_out
