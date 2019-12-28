require 'set'

if not table.unpack then table.unpack = unpack end

function taal2string(tt)
	return string.char(table.unpack(tt))
end

function string2taal(tt)
	return table.pack(string.byte(tt))
end

function log(...)
	if not verboos then return end
	local t = {...}
	local r = {}
	if #t == 0 then print(); return end
	for i,v in ipairs(t) do
		if type(v) == 'table' then
			r[#r+1] = unlisp(v)
		else
			r[#r+1] = tostring(v)
		end
		r[#r+1] = '\t'
	end
	local s = table.concat(r)
	print(s)
end

function emap(exp, fn, ...)
	if isatoom(exp) then
		return fn(exp, ...)
	end
	local s = {}
	if exp.f then
		s.f = fn(exp.f, ...)
	end
	if exp.a then
		s.a = fn(exp.a, ...)
	end
	if exp.o then
		s.o = fn(exp.o, ...)
	end
	for i,v in ipairs(exp) do
		s[i] = fn(v, ...)
	end
	return s
end

function lenc(t)
	if type(t) == 'number' then
		return t
	elseif type(t) == 'string' then
		return string.format('%q', t)
	elseif type(t) == 'table' then
		local r = {}
		r[#r+1] = '{'
		for k,v in pairs(t) do
			r[#r+1] = lenc(k)..'='..lenc(v)
			r[#r+1] = ','
		end
		if r[#r] == ',' then r[#r] = nil end
		r[#r+1] = '}'
		return table.concat(r)
	else
		return tostring(t)
	end
end

function set2lijst(s, volgorde)
	local t = {}
	for k in pairs(s) do
		t[#t+1] = k
	end
	if volgorde then
		table.sort(t, volgorde) 
	end
	return t
end

function see(t)
	if type(t) == 'table' then
		print('{')
		for k,v in pairs(t) do print('  '..tostring(k),v) end
		print('}')
	else
		print(t)
	end
end

function seerec(t,tabs)
	local tabs = tabs or ''
	if type(t) == 'table' then
		print(tabs..'{')
		for k,v in pairs(t) do seerec(k, tabs..'  ') ; seerec(v, tabs..'    ') end
		print(tabs..'}')
	else
		print(tabs..tostring(t))
	end
end

function file(name, data)
	if not data then
		local f = io.open(name, 'r')
		if not f then return false, 'bestand niet gevonden: '..name  end --error('file-not-found ' .. name) end
		data = f:read("*a")
		f:close()
		return data or ""
	else
		local f = io.open(name, 'w')
		assert(f, 'onopenbaar: '..name)
		f:write(data)
		f:close()
	end
end
bestand = file
lees = file

function push(t,v) t[#t+1] = v end
function pop(t)
	local v = t[#t]
	t[#t] = nil; 
	return v
end
function peek(t,n)
	local n = n or 0
	return t[#t-n]
end

-- escapeer alles voor printen tussen enkele quotes
function escape(t)
	t = t:gsub([[\]], [[\\]])
	t = t:gsub([[']], [[\']])
	t = t:gsub('\x1B', '\\e')
	t = t:gsub('\n', '\\n')
	t = t:gsub('\r', '\\r')
	t = t:gsub('\t', '\\t')
	return t
end

function unescape(t)
	t = t:gsub([[\\]], [[\]])
	t = t:gsub([[\']], [[']])
	t = t:gsub('\\e', '\x1B')
	t = t:gsub('\\n', '\n')
	t = t:gsub('\\r', '\r')
	t = t:gsub('\\t', '\t')
	return t
end

function spairs(t)
	if type(t) ~= 'table' then
		error('kan alleen over tabellen itereren')
	end
	local keys = {}
	for key in pairs(t) do
		table.insert(keys, key)
	end
	table.sort(keys, function (a,b) return tostring(a) < tostring(b) end)
	local index = 1

	return function()
		local key = keys[index]
		index = index + 1
		local val = t[key]
		return key,val
	end
end

-- Print contents of `tbl`, with indentation.
-- `indent` sets the initial level of indentation.
function tprint (tbl, indent)
	local indent = indent or 0
	local ks = {}

  for k, v in spairs(tbl) do
    local formatting = string.rep("  ", indent) .. k .. ": "
    if type(v) == "table" then
      print(formatting)
      tprint(v, indent+1)
    elseif type(v) == 'boolean' then
      print(formatting .. tostring(v))		
    else
      print(formatting .. v)
    end
  end
end

function tsv(t)
	local m = {}
	for line in t:gmatch('([^\n]*)\n?') do
		local r = {}
		for op in line:gmatch('([^\t]*)\t?') do
			table.insert(r, op)
		end
		table.insert(m, r)
	end
	return m
end

-- hex
function hex_encode(txt)
	local res = {}
	for i=1,#txt do
		table.insert(res, string.format("%02x", string.byte(txt:sub(i,i))))
	end
	return table.concat(res)
end

function hex_decode(hex)
	local res = {}
	for i=1,#hex-1,2 do
		local sub = hex:sub(i,i+1)
		local num = tonumber(sub, 16)
		table.insert(res, string.char(num))
	end
	return table.concat(res)
end

-- network int
function ntoh(num)
    local mul = 0x1
    local res = 0
    for i=1,#num do
        res = res + mul * string.byte(num:sub(i,i))
        mul = mul * 0x100
    end
    
    return res
end

function hton(num, len)
	local n = {}
	for i=1,len do
		n[i] = num % 0x100
		num = math.floor(num / 0x100)
	end
	return string.char(table.unpack(n))
end

color = {
	red = '\x1B[31m',
	green = '\x1B[32m',
	yellow = '\x1B[33m',
	blue = '\x1B[34m',
	purple = '\x1B[35m',
	cyan = '\x1B[36m',
	gray = '\x1B[37m',

	brightred = '\x1B[91m',
	brightyellow = '\x1B[93m',
	brightcyan = '\x1B[96m',
	white = '\x1B[97m',
}
color[1],color[2],color[3],color[4],color[5],color[6],color[7],color[8] = color.red,color.green,color.yellow,color.purple,color.cyan

ansi = {
	regelbegin = '\x1B[G',
	wisregel = '\x1B[2K',
	normal = '\x1B[0m',
	bold = '\x1B[1m',
	italic = '\x1B[3m',
	underline = '\x1B[4m',
}

if false then

function ls(dir)
	local dir = dir or '.'
	local ls = io.popen('ls')
	local d = {}
	for file in ls:lines() do
		table.insert(d, file)
	end
	return d
end

end
