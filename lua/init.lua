ops = require 'lua/ops'

local objects = {}

function liststring(tt)
	local res = {'['}
	for i,v in ipairs(tt) do
		table.insert(res, tostring(v):sub(1,10))
		if i ~= #tt then
			table.insert(res, ' ')
		end
	end
	table.insert(res, ']')
	return table.concat(res)
end

function dictstring(tt)
	-- regular dict
	local res = {'{'}
	for k,v in pairs(tt) do
		table.insert(res, tostring(k):sub(1,10))
		table.insert(res, '=')
		if type(v) == 'string' then
			table.insert(res, string.format('%q', v:sub(-10)))
		else
			table.insert(res, tostring(v):sub(1,10))
		end
		if next(tt,k) then
			table.insert(res, ' ')
		end
	end
	table.insert(res, '}')
	return table.concat(res)
end

function eval(a)
	if type(a) == 'table' then
		if getmetatable(a) then
			if getmetatable(a).__call then
				return eval(a())
			else
				return tostring(a)
			end
		elseif a.list then
			return liststring(tt)
		else
			return dictstring(tt)
		end
	else
		return tostring(a)
	end
end



function magic(name, eval)
	local tt = {sas = true, magic = true}
	local mt = {}
	
	-- default values
	for k,v in pairs(ops) do
		mt[k] = v
	end
	
	-- unique
	function mt:__tostring()
		return name
	end
	
	mt.__call = eval
	
	setmetatable(tt,mt)
	
	return tt
end

now = magic("now", function ()
	local s,ns = sas.now()
	return s + ns / 1e9
end)

sas.ports = {}
sas.files = {}

function file(name)
	local tt = {}
	setmetatable(tt, {
		__tostring = function ()
			return 'file(' .. name .. ')'
		end;
		__index = function (t,k,v)
			if k == 'lines' then
				local f = io.open(name, 'r')
				local lines = {}
				for line in f:lines() do
					table.insert(lines, line)
				end
				return lines
			end
		end;
	})
	return tt
end

function server(port)
	-- cache
	if sas.ports[port] then
		return sas.ports[port]
	end
	
	-- create and store
	local tt = { sas = true, val = sas.server(port) }
	if not tt.val then
		return nil
	end
	sas.ports[port] = tt
	sas.files[tt.val] = tt
	
	-- clients
	local clients = {sas = true, val = {}, hist = {}, out = nil}
	setmetatable(clients, {
		__index = function (t,k,v)
			if k == 'input' then
				return magic("server("..port..").clients.input", function ()
					return dictstring(clients.val)
				end)
			elseif k == 'delta' then
				return magic("server("..port..").clients.delta", function ()
					return liststring(clients.hist)
				end)
			elseif k == 'kids' then
				return { "input", "delta" }
			end
		end;
		__call = function ()
			local tt = {'['}
			for fd,buf in pairs(clients.val) do
				table.insert(tt, tostring(fd))
				if next(clients.val,fd) then
					table.insert(tt, ' ')
				end
			end
			table.insert(tt, ']')
			return table.concat(tt)
		end;
		__tostring = function ()
			return 'server('..port..').clients'
		end;
		__len = function ()
			local tt = {sas=true}
			setmetatable(tt, {
				__tostring = function ()
					return '#server('..port..').clients'
				end;
				__call = function ()
					local count = 0
					for k in pairs(clients.val) do
						count = count + 1
					end
					return count
				end;
			})
			return tt
		end;
	})
	
	setmetatable(tt, {
		__tostring = function ()
			return 'server(' .. port .. ')'
		end;
		__index = function (t,k,v)
			if k == 'clients' then
				return clients
			elseif k == 'kids' then
				return { 'clients' }
			end
		end;
	})
	return tt
end

function onaccept(client, server)
	local cli = sas.files[server].clients
	cli.val[client] = ""
	cli.hist[#cli.hist + 1] = client .. '+'
end

function onclose(client, server)
	local cli = sas.files[server].clients
	cli.val[client] = "<closed>"
	cli.hist[#cli.hist + 1] = client .. '-'
end

function isobject(v)
	return type(v) == 'table' and v.sas
end

function dbg()
	-- top right
	io.write("\x1B[1;40H")
	
	for name in pairs(objects) do
		io.write("\x1B[40G\x1B[K")
		io.write(name .. " =\t" .. eval(objects[name]))
		io.write("\x1B[B")
	end
	
	io.write("\x1B[40G\x1B[K\x1B[B")
	io.write("\x1B[40G\x1B[K\x1B[B")
	io.write("\x1B[40G\x1B[K\x1B[B")
	io.write("\x1B[40G\x1B[K\x1B[B")
	io.write("\x1B[40G\x1B[K\x1B[B")
end
setmetatable(_G, {
	__newindex = function (t,k,v)
		rawset(t,k,v)
		if isobject(v) then
			objects[k] = v
		end
	end;
})

dofile "lua/web.lua"