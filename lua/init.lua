require 'lua/util'
ops = require 'lua/ops'

function print(...)
	local args = table.pack(...)
	for i,arg in ipairs(args) do
		io.write(tostring(arg) .. '\t')
	end
	io.write('\n')
end

magics = {}
watches = {}

local watches, fresh

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
		table.insert(res, tostring(k):sub(1,4))
		table.insert(res, '=')
		if type(v) == 'string' then
			table.insert(res, string.format('%q', v:sub(-4)))
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

read2magic, write2magic, accept2magic = {}, {}, {}

function accept(id, magic)
	read2magic[id] = magic
	accept2magic[id] = true
	return "accept("..id..")"
end

function read(id, magic)
	print('READ')
	print(debug.traceback())
	read2magic[id] = magic
	return "read("..id..")"
end

function write(id, magic)
	write2magic[id] = magic
end

function close(id, magic)
	read2magic[id] = nil
	write2magic[id] = nil
	accept2magic[id] = nil
end

function encode(text)
	return string.format('%q', text:sub(-5)):gsub('\\\n', '\\n')
end

function server(port)
	local id = sas.server(port)
	if not id then
		error("bind failed")
	end
	
	local s = magic("server("..port..")")
	
	s.val = {
		id = id,
		port = port,
		cli = {}, -- magics
	}
	s.text = '#'..id
	s.triggers[s.name] = accept(id, s)
	
	-- clients!
	local cs = magic(s.name..".cli")
	s.cli = cs
	
	cs.val = s.val.cli
	cs.text = '{}'
	s.events[s.name..".cli"] = cs
	
	function cs:update()
		cs.text = dictstring(cs.val)
	end
	
	-- individual !
	function s:accept(cid, addr)
		local c = magic(cs.name..'(#'..cid..')')
		c.val = {
			id = cid,
			addr = addr,
			data = '',
		}
		print('cid', cid, c)
		c.triggers[c.name] = read(cid, c)
		
		local data = magic(c.name .. '.data')
		data.val = ''
		data.text = '<empty>'
		function data:update()
			self.val = c.val.data
			self.text = encode(self.val)
		end
		c.data = data
		c.events.data = data
		
		function c:read(data) -- primary
			self.val.data = self.val.data .. data
			self.text = encode(self.val.data)
		end
		
		function c:close()
			close(cid, c)
			self.text = '<closing>'
		end
		
		self.val.cli[cid] = c
	end
	return s
end

function lines(data)
	local m = magic("lines")
	
	m.triggers["source"] = data
	data.events["lines"] = m
	m.val = {}
	m.last = 1
	m.text = "0 lines"
	
	function m:update()
		while true do
			local eol = data.val:find("\n", m.last)
			if not eol then
				break
			end
			m.val[#m.val + 1] = data.val:sub(m.last, eol)
			m.last = eol + 1
		end
		m.text = #m.val.." lines"
	end
	trigger(m)
	return m
end

function split(data, sep)
	local m = magic("split")
	
	m.triggers["split"] = data
	data.events["parts"] = m
	m.val = {}
	m.last = 1
	m.text = "0 parts"
	
	function m:update()
		while true do
			local eol = data.val:find(sep, m.last)
			if not eol then
				break
			end
			m.val[#m.val + 1] = data.val:sub(m.last, eol)
			m.last = eol + 1
		end
		m.text = #m.val.." parts"
	end
	trigger(m)
	return m
end

function magic(name)
	local m = {
		-- lists of others
		triggers = {
			-- no initial triggers
		},
		events = { 
			watchdog = watchdog
		},
		update = function () return end,
		val = nil,
		name = name,
	}
	
	magics[name] = m
	
	setmetatable(m, {
		__tostring = function () return name end
	})
	
	dbg()
	
	return m
end

function trigger(magic)
	if magic.update then
		magic:update()
	end
	
	for name,val in pairs(magic.events) do
		trigger(val)
	end
end

function refresh()
	trigger(fresh)
end

function dbg()
	-- store
	io.write("\x1B[s")
	
	-- top right
	io.write("\x1B[1;40H")
	
	for name,magic in pairs(magics) do
		if name ~= "watchdog" then
			io.write("\x1B[40G\x1B[K")
			if magic.val and magic.text then
				io.write(name .. " =\t" .. tostring(magic.text))
			else
				io.write(name .. " =\t" .. tostring(magic.val))
			end
			io.write("\x1B[B")
		end
	end
	
	io.write("\x1B[40G\x1B[K\x1B[B")
	io.write("\x1B[40G\x1B[K\x1B[B")
	io.write("\x1B[40G\x1B[K\x1B[B")
	-- restore
	io.write("\x1B[u")
	io.write("\x1B[A\n")
end

watchdog = magic("watchdog")
watchdog.update = dbg
--watchdog.events.watchdog = nil

dofile "lua/satis.lua"
dbg()