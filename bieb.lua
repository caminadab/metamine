require 'exp'
require 'util'

local niets = {}

local listmeta = {}
function listmeta:__tostring()
	return '[' .. table.concat(map(self, function(a) return tostring(a) end), ',') .. ']'
end

function bieb()
	local inn = {}
	local vars = {}

	local bieb = {

	-- net
	['tcp.verbind'] = function (args)
		require 'socket'
		local host,poort = args[1],args[2]
		--socket.
	end;
		
	['⊤'] = true,
	['⊥'] = false,
	teken = true,
	log2 = true,
	log10 = math.log10,
	puts = true,
	call = true,
	['τ'] = math.pi*2,
	pi = math.pi,
	init = true,
	fout = true,
	['scherm.ververst'] = true,
	inkleur = true,

	rgb = true,

	-- meta
	['_var'] = function (a)
		local index, set = a[1], a[2]
		local ret = vars[index]
		-- start
		for exp in pairs(set) do
			if exp ~= nil then
				ret = exp
			end
		end
		vars[index] = ret
		return ret
	end;

	_prevvar = function(index)
		return vars[index]
	end;

	-- web
	consolelog =  function(s) print(s) end;
	requestAnimationFrame = function () error('niet beschikbaar') end;
	schrijfHtml = function () error('niet beschikbaar') end;

	contextVan = function () error('niet beschikbaar') end;
	wisCanvas = function () error('niet beschikbaar') end;
	looptijd = 0;

	vierkant = function() error('niet beschikbaar') end;
	boog = function() error('niet beschikbaar') end;
	label = function() error('niet beschikbaar') end;
	rechthoek = function() error('niet beschikbaar') end;
	cirkel = function() error('niet beschikbaar') end;
	lijn = function() error('niet beschikbaar') end;
	['muis.klik'] = false,
	['muis.klik.begin'] = false,
	['muis.klik.eind'] = false,
	['muis.sleep'] = false, -- (pad = (van, via, naar))
	['muis.x'] = false,
	['muis.y'] = false,
	['muis.pos'] = false,
	['muis.beweegt'] = false,

	-- toetsenbord
	['toets.neer'] = true,
	['toets.neer.begin'] = true,
	['toets.neer.eind'] = true,

	metInvoer = true, -- X_X


	['_'] = function(a)
		local a,b = a[1],a[2]
		if type(a) == 'string' then
			return a:byte(b+1)
		elseif type(a) == 'table' then
			return a[b+1]
		else
			return a(b)
		end
	end;

	['_u'] = function(a, b)
		return a:byte(b)
	end;

	['⊤'] = true;
	['⊥'] = false;

	-- io
	['stduit.schrijf'] = function(a)
		do
			print(combineer(w2exp(a)))
			return true
		end
		if type(a) == 'table' and #a > 1 then
			local txt = true
			for i,v in ipairs(a) do
				if type(v) == 'number' and v % 1 == 0 and v > 0 then
					-- goed
				else
					txt = false
					break
				end
			end
			if txt then
				print(string.char(table.unpack(a)))
				return 0
			end
		end
			
		if opt and opt.L then print() end;
		print(combineer(w2exp(a)))
		return 0
	end,

	syscall = function(a) error 'SYSCALL' end, 
	xcb_connect = true,


	-- tekening
	rechthoek = true,

	-- willekeurig ×
	aselect = function (a, b)
		return math.random(a, b-1)
	end,

	-- wiskunde
	co = 3,
	atoom = function(id) return setmetatable({id=id}, {__tostring=function()return 'atoom'..id end}) end,
	max = function(args) return math.max(args[1], args[2]) end,
	min = function(args) return math.min(args[1], args[2]) end,
	int = math.floor,
	abs = math.abs,
	absd = math.abs,
	absi = math.abs,
	ceil = math.ceil,
	["'"] = true,
	['nu'] = (function()
		local socket = require 'socket'
		return socket.gettime()
	end) (10),
	starttijd = true,
	['start1'] = (function()
		local socket = require 'socket'
		return socket.gettime()
	end) (10),
	os.time(),
	['inverteer'] = true; -- sure
	['sqrt'] = function(a) return math.sqrt(a) end;
	['niets'] = false; --"niets";
	['min'] = function(a,b) return math.min(a,b) end;
	['mod'] = function(a,b) return a % b end;

	['¬'] = function(b)
		return not b
	end;

	['!'] = function(n)
		local a = 1
		for i=1,n do
			a = a * i
		end
		return a
	end;

	-- linksassociatief
	-- cartesisch product
	['×'] = function(a)
		local a,b = a[1],a[2]
		local t = {}
		for i,aa in ipairs(a) do
			for i,bb in ipairs(b) do
				t[#t+1] = setmetatable({aa, bb}, getmetatable(a))
			end
		end
		setmetatable(t, listmeta)
		return t
	end;
			
	['kortsluit'] = function(a,b)
		-- a = origineel
		-- b = verbeterd
	end;

	['+i'] = true,
	['-i'] = true,
	['*i'] = true,
	['/i'] = true,
	['^i'] = true,
	['modi'] = true,
	['entier'] = function(a) return math.floor(a) end,
	['ceiling'] = function(a) return math.ceil(a) end,
 
	['+i'] = function(a,b) return a + b end,
	['-i'] = function(a,b) return a - b end,
	['*i'] = function(a,b) return a * b end,
	['/i'] = function(a,b) return a / b end,
	['^i'] = function(a,b) return a ^ b end,
	['modi'] = function(a,b) return a % b end,

	['+d'] = function(a,b) return a + b end,
	['-d'] = function(a,b) return b and a - b or -a end,
	['*d'] = function(a,b) return a * b end,
	['/d'] = function(a,b) return a / b end,
	['^d'] = function(a,b) return a ^ b end,
	['modd'] = function(a,b) return a % b end,

	['^f'] = function(a, b)
		return function (x)
			for i=1,b do
				x = a(x)
			end
			return x
		end
	end;

	['+'] = function(a) return a[1] + a[2] end;
	['-'] = function(a) return -a end;
	['·'] = function(a) return a[1] * a[2] end;
	['/'] = function(a) return a[1] / a[2] end;
	['√'] = function(a) return math.pow(a, 0.5) end;

	['^'] = function(a)
		if type(a[1]) == 'function' then
			return function (x)
				for i=1,a[2] do
					x = (a[1])(x)
				end
				return x
			end
		else
			return a[1] ^ a[2]
		end
	end;
	['%'] = function(a) return a / 100 end;

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

	['∘'] = function(a)
		assert(type(a[1]) == 'function', '@1 is geen functie')
		assert(type(a[2]) == 'function', '@2 is geen functie')
		return function(...)
			return a[2](a[1](...))
		end
	end;

	['|'] = function(a)
		for i,v in pairs(a) do
			if v ~= nil and v ~= false then
				return v
			end
		end
	end;

	['→'] = function(param, f)
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
	['='] = function(a)
		if tonumber(a[1]) and tonumber(a[2]) then
			return a[1] == a[2]
		end
		return lenc(a[1]) == lenc(a[2])
	end;
	['>'] = function(a) return tonumber(a[1]) > tonumber(a[2]) end;
	['<'] = function(a) return tonumber(a[1]) < tonumber(a[2]) end;
	['≠'] = function(a) return a[1] ~= a[2] end;
	['≈'] = function(a) return math.abs(a[1]-a[2]) < 0.00001 end;

	['..'] = function(a)
		local a,b = a[1], a[2]
		local r = {}
		if a > b then
			for i=a-1,b,-1 do
				r[#r+1] = i
			end
		elseif a == b then
			return {}
		else
			for i=a,b-1 do
				r[#r+1] = i
			end
		end
		setmetatable(r, listmeta)
		return r
	end;

	['‖'] = function(a)
		local a,b = a[1], a[2]
		if type(a) == 'string' or type(b) == 'string' then
			return tostring(a) .. tostring(b)
		end
		local j = 1
		local t = {f='[]'}
		--if isatoom(a) then a = {a} end
		--if isatoom(b) then b = {b} end
		for i,v in ipairs(a) do t[j] = v; j=j+1 end
		for i,v in ipairs(b) do t[j] = v; j=j+1 end
		setmetatable(t, listmeta)
		return t
	end;

	['‖u'] = function(a)
		local a,b = a[1], a[2]
		return a .. b
	end;

	['catu'] = function(t)
		return table.concat(t)
	end;

	-- lib
	['cat'] = function(a,b)
		local r = {f='[]'}
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
		setmetatable(r, listmeta)
		return r
	end;

	-- linq
	['vouw'] = function(a)
		local lijst, func = a[1],a[2]
		local aggr = lijst[1]
		for i = 2,#lijst do
			aggr = func{aggr, lijst[i]}
		end
		return aggr
	end;

	['map'] = function(a)
		local a,b = a[1],a[2]
		local r = {}
		for i=1,#a do --i,v in ipairs(a) do
			local v = a[i]
			local s = b(v)
			r[i] = s
			--print('B', i, v, r[i])
			--assert(s)
		end
		setmetatable(r, listmeta)
		return r
	end;

	['filter'] = function(l,fn)
		local r = {f='[]'}
		for i,v in ipairs(l) do
			if fn(v) then
				r[#r+1] = v
			end
		end
		return r
	end;

	['reduceer'] = function(l,fn)
		local r = {f='[]'}
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
		return {f=',', math.sin(a), math.cos(a)}
	end;

	['∨'] = function(a,b) return a or b end;
	['∧'] = function(a,b) return a and b end;
	['⋁'] = function(a,b) return a or b end;
	['⋀'] = function(a,b) return a and b end;

	['Σ'] = function(a)
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

	['alsHtml'] = function(a) return a end;

	['alsTekst'] = function(a)
		local t
		if a == true then t = 'ja' end 
		if a == false then t = 'nee' end 
		if tonumber(a) then t = tostring(a) end
		if type(a) == 'string' then return a end
		if type(a) == 'table' then
			return string.char(table.unpack(a))
		end
		return tostring(a)
	end;

	['getal'] = function(a)
		return tonumber(string.char(table.unpack(a)))
	end;

	['intd'] = math.floor,

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
	['⇒'] = function(a,b,c)
		if a then return b
		else return c or niets end
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
		local t = {f='[]'}
		for i=van+1,#a do
			t[#t+1] = a[i]
		end
		return t
	end;

	['[]u'] = false,

	['tot'] = function(a,tot)
		local t = {f='[]'}
		for i=1,tot do
			t[#t+1] = a[i]
		end
		return t
	end;

	['deel'] = function(a,b)
		local van,tot = b[1],b[2]
		local t = {f='[]'}
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

	return bieb

end
