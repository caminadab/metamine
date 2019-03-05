require 'ontleed'
require 'oplos'
require 'doe'

local socket = require 'socket'
local server = socket.bind('127.0.0.1','1234')
assert(server)
local sockets = {server}
local coros = {}

function serveer(sock)
	local len
	-- header
	while true do
		coroutine.yield()
		local line = sock:receive('*l')
		if line == '' then
			break
		end
		
		local len0 = line:match('Content%-Length: (%d+)')
		if len0 then
			len = tonumber(len0)
		end
	end

	-- content
	local inn
	local uit
	if len then
		coroutine.yield()
		inn = sock:receive(len)
	end

	-- vertaal
	local function vt()
		return doe0(oplos(ontleed0(inn), 'uit')) or 'fout'
	end
	local ok,uit = pcall(vt, inn)
	if type(uit) ~= 'table' then
		uit = tostring(uit)
	else
		uit = tostring(string.char(table.unpack(uit)))
	end
	local inL = string.format('%q', tostring(inn)):gsub('\n', '\\n')
	local uitL = string.format('%q', uit):gsub('\n', '\\n')

	print(os.date(), inL, uitL)

	-- header
	sock:send("HTTP/1.0 200 OK\r\n")
	sock:send("Host: localhost\r\n")
	sock:send("Server: Lua 5.2\r\n")
	sock:send("Content-Length: "..#uit.."\r\n")
	sock:send("\r\n")

	sock:send(uit)

	sock:close()
end

while true do
	local rs = socket.select(sockets)

	-- connect
	if rs[1] == server then
		local client = server:accept()
		sockets[client] = #sockets+1
		sockets[#sockets+1] = client
		coros[client] = coroutine.create(serveer, client)
		coroutine.resume(coros[client], client)
		table.remove(rs, 1)
	end

	-- data
	for i=#rs,1,-1 do
		local client = rs[i]
		local unfinished,err = coroutine.resume(coros[client])
		if err then print('ERR', err) end
		if not unfinished then
			table.remove(sockets, sockets[client]) --client)
			sockets[client] = nil
			coros[client] = nil
		end
	end

end
