local ops = {
	__add = function (a,b) return add(a,b) end;
	__sub = function (a,b) return sub(a,b) end;
	__mul = function (a,b) return mul(a,b) end;
	__div = function (a,b) return div(a,b) end;
	__mod = function (a,b) return mod(a,b) end;
	__pow = function (a,b) return pow(a,b) end;
	__unm = function (a) return unm(a) end;
	__concat = function (a,b) return concat(a,b) end;
	__len = function (a) return len(a) end;
	__eq = function (a,b) return eq(a,b) end;
	__lt = function (a,b) return lt(a,b) end;
	__le = function (a,b) return le(a,b) end;
}

function eval(a)
	if type(a) == 'table' and getmetatable(a).__call then
		return a()
	else
		return tostring(a)
	end
end

function op2(symbol)
	local fn = loadstring("return function(a,b) return a"..symbol.."b end")()
	return function (a,b)
		local tt = {}
		local mt = {}
		
	
		-- default values
		for k,v in pairs(ops) do
			mt[k] = v
		end
		
		mt.__call = function ()
			return fn(eval(a), eval(b))
		end
		mt.__tostring = function ()
			return "("..tostring(a).." "..symbol.." "..tostring(b)..")"
		end
		
		setmetatable(tt, mt)
		
		return tt
	end
end

function op1(symbol)
	local fn = loadstring("return function(a) return "..symbol.."a end")()
	return function (a)
		local tt = {}
		local mt = {}
		
	
		-- default values
		for k,v in pairs(ops) do
			mt[k] = v
		end
		
		mt.__call = function ()
			return fn(eval(a))
		end
		
		mt.__tostring = function ()
			return symbol.." "..tostring(a)
		end
	
		setmetatable(tt, mt)
		return tt
	end
end

add = op2('+')
sub = op2('-')
mul = op2('*')
div = op2('/')
mod = op2('%')
pow = op2('^')
unm = op1('-')
concat = op2('..')
len = op1('#')
eq = op2('==')
lt = op2('<')
le = op2('<=')

function magic(name, eval)
	local tt = {magic = true}
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

my = {}

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
	local tt = { val = sas.server(port) }
	if not tt.val then
		return nil
	end
	sas.ports[port] = tt
	sas.files[tt.val] = tt
	
	-- clients
	local clients = {val = {}, out = nil}
	setmetatable(clients, {
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
			local tt = {}
			setmetatable(tt, {
				__tostring = function ()
					return '#server('..port..').clients'
				end;
				__call = function ()
					return #clients.val
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
			end
		end;
	})
	return tt
end

function dbg()
	-- top right
	io.write("\x1B[1;40H")
	
	for k in pairs(my) do
		if _G[k] ~= nil and type(_G[k]) ~= 'function' then
			io.write("\x1B[B\x1B[40G\x1B[K")
			io.write(k .. " =\t" .. eval(_G[k]))
		end
	end
	
	io.write("\x1B[B\x1B[40G\x1B[K")
	io.write("\x1B[B\x1B[40G\x1B[K")
	io.write("\x1B[B\x1B[40G\x1B[K")
	io.write("\x1B[B\x1B[40G\x1B[K")
end
setmetatable(_G, {
	__newindex = function (t,k,v)
		if v == nil then
			rawset(my,k,nil)
		else
			rawset(my,k,true)
		end
		rawset(t,k,v)
	end;
})

dofile "lua/web.lua"