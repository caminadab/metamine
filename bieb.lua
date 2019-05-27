require 'exp'
require 'util'
require 'naarlua'
require 'naarjavascript'

local jslibtaal = {string.byte(javascriptbieb,1,#javascriptbieb)}
jslibtaal.fn = '[]'

bieb = {
	-- rochel
	['open-lees'] = true,
	syscall = true,
	log2 = true,

	-- tekening
	rechthoek = true,
	groen = true,
	rood = true,
	wit = true,
	zwart = true,

	-- wiskunde
	looptijd = 3,
	co = 3,
	atoom = function(id) return '###' .. id end;
	max = math.max,
	min = math.min,
	int = math.floor,
	abs = math.abs,
	plafond = math.ceil,
	["'"] = true,
	['nu'] = (function()
		local socket = require 'socket'
		return socket.gettime()
	end) (10),
	starttijd = true,
	['start'] = (function()
		local socket = require 'socket'
		return socket.gettime()
	end) (10),
	os.time(),
	['inverteer'] = true; -- sure
	['wortel'] = true; -- sure
	['ja'] = true; 
	['nee'] = false; 
	['niets'] = false; 
	['min'] = function(a,b) return math.min(a,b) end;
	['mod'] = function(a,b) return math.modf(a,b) end;

	['jslib'] = jslibtaal,
	['javascript'] = function(fn) 
		local code,err = naarjavascript(fn)
		if not code and verboos then print('GEEN JAVASCRIPT: '..err) end
		local a = table.pack(string.byte(code, 1, #code))
		a.fn = '[]'
		return a
	end;

	['!'] = function(n)
		local a = 1
		for i=1,n do
			a = a * n
		end
		return a
	end;

	-- linksassociatief
	['xx'] = function(a,b)
		--if type(a) == 'number' and type(b) == 'number' then
			--return {
			
		if a.is.tupel and b.is.tupel then
			for i=1,#b.val do
				a.val[#a.val+1] = b.val[i]
			end
			return a
		else
			if a.is.tupel then
				a.type.lang = a.type.lang + 1
				a.val[#a.val+1] = b.val
			end
		end
	end;
			
	['lua'] = function(func)
		local code = naarlua(func)
		local a = table.pack(string.byte(code, 1, #code))
		a.fn = '[]'
		return a
	end;

	['kortsluit'] = function(a,b)
		-- a = origineel
		-- b = verbeterd
	end;

	['+'] = function(a,b) return a + b end;
	['-'] = function(a,b) if b then return a - b else return -a end end;
	['*'] = function(a,b) return a * b end;
	['/'] = function(a,b) return a / b end;
	['^'] = function(a,b)
		if type(a) == 'function' then
			return function (x)
				for i=1,b do
					x = a(x)
				end
				return x
			end
		else
			return a ^ b
		end
	end;
	['%'] = function(a) return a / 100 end;
	['[]'] = function(...) return {fn='[]',...} end;
	['{}'] = function(...)
		local t = {...}
		local s = {is={set=true},set={}}
		for _,v in pairs(t) do
			s.set[v] = true
		end
		return s
	end,

	['ontleed'] = function(a)
		--local code = string.char(table.unpack(a))
		local code = a
		local data = ontleed(code)
		return data
	end;

	['oplos'] = function(exp)
		local obj = oplos(exp)
		return function(k)
			return obj[string.char(table.unpack(k))]
		end
	end;

	['doe'] = function(exp)
		return doe0(exp)
	end;

	['@'] = function(a,b)
		assert(type(a) == 'function', a)
		assert(type(b) == 'function', b)
		return function(...)
			return b(a(...))
		end
	end;

	['|'] = function(a,b)
		local fa = type(a) == 'function'
		local fb = type(b) == 'function'
		--if fa ~= fb then return 'fout' end
		--[[
		if fa and fb then
			return function(...)
				local ta = a(...)
				local tb = b(...)
				if not ta == not tb then
					return nil
				end
				return ta or tb
			end
		end
		]]
		if a and b then return 'fout' end
		return a or b
	end;

	['->'] = function(param, f)
		return function(a)
			return doe(substitueer(f, param, a))
		end
	end;

	['coproduct'] = function(f,g)
		return function(...)
			return f(...) or g(...)
		end
	end;

	['#'] = function(a) return #a end;
	['='] = function(a,b)
		if tonumber(a) and tonumber(b) then
			return a == b
		end
		return unlisp(a)==unlisp(b)
	end;
	['>'] = function(a,b) return tonumber(a) > tonumber(b) end;
	['<'] = function(a,b) return tonumber(a) < tonumber(b) end;
	['!='] = function(a,b) return a ~= b end;
	['~='] = function(a,b) return math.abs(a-b) < 0.00001 end;
	['..'] = function(a,b)
		local r = {}
		for i=a,b-1 do
			r[i-a+1] = i
		end
		return r
	end;

	['||'] = function(a,b)
		if isatoom(a) or isatoom(b) or a.fn ~= '[]' or b.fn ~= '[]' then return "fout" end
		local j = 1
		local t = {fn='[]'}
		--if isatoom(a) then a = {a} end
		--if isatoom(b) then b = {b} end
		for i,v in ipairs(a) do t[j] = v; j=j+1 end
		for i,v in ipairs(b) do t[j] = v; j=j+1 end
		return t
	end;

	-- lib
	['cat'] = function(a,b)
		local r = {fn='[]'}
		for i,v in ipairs(a) do
			for i,v in ipairs(v) do
				r[#r+1] = v
			end
			if b and i ~= #a then
				for i,b in ipairs(b) do
					r[#r+1] = b
				end
			end
		end
		return r
	end;

	-- linq
	['map'] = function(a,b)
		local r = {fn='[]'}
		for i,v in ipairs(a) do
			--print('B', v, b(v))
			r[i] = b(v)
		end
		return r
	end;

	['waarvoor'] = function(l,fn)
		local r = {fn='[]'}
		for i,v in ipairs(l) do
			if fn(v) then
				r[#r+1] = v
			end
		end
		return r
	end;

	-- trig
	['sin'] = math.sin;
	['asin'] = math.asin;
	['cos'] = math.cos;
	['acos'] = math.acos;
	['tan'] = math.tan;
	['atan'] = function(a,b)
		if b then return math.atan2(a,b)
			else return math.atan(a)
		end
	end;
	['sincos'] = function (a)
		return {fn=',', math.sin(a), math.cos(a)}
	end;

	['of'] = function(a,b) return a or b end;
	['en'] = function(a,b) return a and b end;
	['OF'] = function(a,b) return a or b end;
	['EN'] = function(a,b) return a and b end;
	['!'] = function(a) return not a end;

	['som'] = function(a)
		local r = 0
		for i,v in ipairs(a) do
			r = r + v
		end
		return r
	end;

	-- herhaal functie totdat geen resultaat
	['herhaal'] = function(f)
		return function(a)
			local r = a
			while a do
				r = a
				a = f(a)
			end
			return r
		end
	end;

	['tekst'] = function(a)
		local t
		if a == true then t = 'ja' end 
		if a == false then t = 'nee' end 
		if tonumber(a) then t = tostring(a) end
		if type(a) == 'table' then
			t = tostring(toexp(a))
		end
		local t = table.pack(string.byte(tostring(t),1,#tostring(t)))
		t.fn = '[]'
		return t
	end;

	['getal'] = function(a)
		return tonumber(string.char(table.unpack(a)))
	end;

	['int'] = function(a)
		if tonumber(a) then
			return math.floor(a)
		end
		local getal = tonumber(string.char(table.unpack(a)))
		if not getal then return false end
		return math.floor(getal)
	end;

	['cijfer0'] = function(a)
		--return not not (tonumber(a) and #tostring(a) == 1)
		a = tonumber(a)
		return 48 <= a and a <= 57
	end;

	['split'] = function(a,b)
		local r = {}
		local t = {}
		for i,v in ipairs(a) do
			if v == b then
				r[#r+1] = t
				t = {}
			else
				t[#t+1] = v
			end
		end
		return r
	end;

	['unie'] = function(a,b)
		local s = {}
		for v in pairs(a) do s[v] = true end
		for v in pairs(b) do s[v] = true end
		return s
	end;

	['UNIE'] = function(a,b)
		local s = {}
		for v in pairs(a) do s[v] = true end
		for v in pairs(b) do s[v] = true end
		return s
	end;

	['verschil'] = function(a,b)
		local s = {}
		for k,v in pairs(a) do if not b[k] then s[k] = v end end
		return s
	end;

	['lijst'] = 'lijst',

	[':'] = function(a,b)
		if b == bieb.int then
			return tonumber(a) and tonumber(a)%1==0 or type(a) == 'number'
		elseif b == bieb.lijst then
			return type(a) == 'table'
		-- set
		elseif a[b] == true then
			return true
		else
			return false
		end
	end;

	-- aux
	['net-adres'] = function(a)
		local socket = require 'socket'
		local ip = string.char(table.unpack(a))
		return table.pack(ip:match('([^:]*):(.*)'))
  end;
	['bestand-in'] = function(naam)
		local naam = string.char(table.unpack(naam))
		local bestand = io.open(naam, 'r')
		_G.print('OPEN '..naam)
		return {fd = bestand, buf = false}
	end;
	['bestand'] = function(naam)
		return file(naam)
	end;
	['kan-lezen'] = function(b)
		if not b.buf then b.buf = b.fd:read(1024) end
		return b.buf
	end;
	['=>'] = function(a,b)
		if a then return b
		else return false end
	end;
	-- delta componeer
	-- 2@∆3 = 5
	['deltacomp'] = function(val,delta)
		if val == nil then
			return delta
		elseif delta == nil then
			return val
		elseif tonumber(val) then
			return val + delta
		elseif val == true then
			return delta
		else
			print('??', val, delta)
		end
	end;

	-- tekst
	['vind'] = function(a,b)
		for i=1,#a-#b+1 do
			local gevonden = true
			for j=i,i+#b-1 do
				if a[j] ~= b[j-i+1] then
					gevonden = false
					break
				end
			end
			if gevonden then
				return i-1
			end
		end
		return false
	end;

	['vanaf'] = function(a,van)
		local t = {fn='[]'}
		for i=van+1,#a do
			t[#t+1] = a[i]
		end
		return t
	end;

	['tot'] = function(a,tot)
		local t = {fn='[]'}
		for i=1,tot do
			t[#t+1] = a[i]
		end
		return t
	end;

	['deel'] = function(a,b)
		local van,tot = b[1],b[2]
		local t = {fn='[]'}
		for i=van+1,tot do
			t[#t+1] = a[i]
		end
		return t
	end;

	['kies-int'] = function(t)
		return math.random(t[1], t[2]-1)
	end;

	['recursief'] = function(rec)
		-- rec: zelf → (w → zelf(w))

		-- recf: volledig recursieve functie
		local recf = rec(rec)
		return recf

		--return function(waarde)
			--return doe(substitueer(rec, param, a))
	end;
}
