require 'exp'
require 'util'
socket = require 'socket'

local niets = {}

local listmeta = {}
function listmeta:__tostring()
	return '[' .. table.concat(map(self, function(a) return tostring(a) end), ',') .. ']'
end

function bieb()
	local inn = {}
	local vars = {}

	-- host, poort → socket
	local sockets = {}
	-- socket → set(socket)
	local clients = {}
	-- socket → int
	local written = {}
	-- read
	local read = {}

	local bieb = {

	-- canvas
	['pad.begin'] = true,
	['canvas.context'] = true,

	-- functioneel
	['fn.eerste'] = function(x) return x[1] end;
	['fn.tweede'] = function(x) return x[2] end;
	['fn.derde'] = function(x) return x[3] end;
	['fn.vierde'] = function(x) return x[4] end;
	['merge'] = function(fns)
		return function(x)
			local r = {}
			for i,fn in ipairs(fns) do
				r[i] = fn(x)
			end
			return r
		end
	end;
	['dup'] = function(x)
		return {x, x}
	end;
	['id'] = function(x)
		return x
	end;
	['constant'] = function(x)
		return function()
			return x
		end
	end;
	['kruid'] = function(args)
		local fn,x = args[1], args[2]
		return function(y)
			return fn(x,y)
		end
	end;
	['kruidL'] = function(args)
		local fn,y = args[1], args[2]
		return function(x)
			return fn(x,y)
		end
	end;

	-- net

	['model'] = function () end,

	-- host, poort → socket
	['tcp.verbind'] = function (args)
		local host,poort = args[1],args[2]
		if not sockets[host] or not sockets[host][poort] then
			local sock = socket.connect(host, poort)
			sock:settimeout(0)
			sockets[host] = socket[host] or {}
			sockets[host][poort] = sock
			written[sock] = 0
			read[sock] = ''
		end
		return sockets[host][poort]
	end;

	-- host, poort → socket
	['tcp.bind'] = function (args)
		local host,poort = args[1],args[2]
		if not sockets[host] or not sockets[host][poort] then
			local sock = socket.bind(host, poort)
			sock:settimeout(0)
			sockets[host] = socket[host] or {}
			sockets[host][poort] = sock
			clients[host] = {}
		end
		return sockets[host][poort]
	end;

	-- socket → set(socket)
	['tcp.accepteer'] = function(sock)
		clients[sock] = clients[sock] or {}
		while true do
			local client = sock:accept()
			if client then
				client:settimeout(0)
				table.insert(clients[sock], client)
			else
				break
			end
		end
		return clients[sock]
	end;
			
	-- socket, data → socket
	['tcp.schrijf'] = function(args)
		local sock, data = args[1], args[2]
		local n = written[sock] or 0
		if type(data) == 'table' then
			data = string.char(table.unpack(data))
		end
		if #data > n then
			local w = sock:send(data, n+1)
			if not tonumber(w) then
				return
			end
			written[sock] = w
		end
		return written[sock]
	end;

	-- socket → data
	['tcp.lees'] = function(sock)
		read[sock] = read[sock] or ''
		local data = sock:receive()
		if data then
			read[sock] = read[sock] .. data
		end
		return read[sock]
	end;
		
	['⊤'] = true,
	['sorteer'] = function (a) return table.sort(a[0], a[1]) end,
	['dt'] = 1/60, -- terminal altijd
	['⊥'] = false,
	log2 = function (a) return math.log(a, 2) end,
	log10 = math.log10,
	['τ'] = math.pi*2,
	['∅'] = {},
	['π'] = math.pi,
	misschien = true,
	fout = true,
	['scherm.ververst'] = true,
	verf = true,
	schaal = true,

	rgb = true,

	-- meta
	['_var'] = function (a)
		local index, set = a[1], a[2]
		local ret = vars[index]
		-- start
		for i, val in pairs(set) do
			if val ~= nil then
				ret = val
			end
		end
		vars[index] = ret
		return ret
	end;

	_V = function(index)
		return vars[index]
	end;

	-- web
	['console.log'] =  function(s) print(s) end;
	['herhaal.langzaam'] = function (f) f(1/24) end; --error('niet beschikbaar') end;
	['canvas.context2d'] = function () error('niet beschikbaar') end;
	['canvas.context3d'] = function () error('niet beschikbaar') end;
	['canvas.wis'] = function () error('niet beschikbaar') end;

	vierkant = function() return('vierkant') end;
	boog = function() return('boog') end;
	label = function() return('label') end;
	rechthoek = function() return('rechthoek') end;
	cirkel = function() return('cirkel') end;
	lijn = function() return('lijn') end;
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

	['invoer.registreer'] = function (a) return a end;


	['_'] = function(a)
		local a,b = a[1],a[2]
		if type(a) == 'string' then
			return a:byte(b+1)
		elseif type(a) == 'table' then
			return a[b+1]
		elseif type(a) == 'function' then
			return a(b)
		else
			return a
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
			io.write(combineer(w2exp(a)))
			io.flush()
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
				io.write(string.char(table.unpack(a)))
				return 0
			end
		end
			
		if opt and opt.L then print() end;
		io.write(combineer(w2exp(a)))
		return 0
	end,

	syscall = function(a) error 'SYSCALL' end, 
	xcb_connect = true,

	-- wiskunde
	atoom = function(id) return setmetatable({id=id}, {__tostring=function()return 'atoom'..id end}) end,
	max = function(args) return math.max(args[1], args[2]) end,
	min = function(args) return math.min(args[1], args[2]) end,
	int = math.floor,
	abs = math.abs,
	absd = math.abs,
	absi = math.abs,
	ceil = math.ceil,
	["'"] = true,
	['inverteer'] = true; -- sure
	['sqrt'] = math.sqrt;
	['niets'] = nil;
	['min'] = function(a) return math.min(a[1],a[2]) end;
	['mod'] = function(a) return a[1] % a[2] end;

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
	['%'] = function(a) return a / 100 end;

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

	-- concatenate
	['‖'] = function(a)
		local a,b = a[1], a[2]
		if type(a) == 'string' or type(b) == 'string' then
			if type(b) == 'table' then
				return a .. string.char(table.unpack(b))
			elseif type(a) == 'table' then
				return string.char(table.unpack(a)) .. b
			else
				return tostring(a) .. b
			end
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

	['zip'] = function(a)
		local a,b = a[1],a[2]
		local v = {}
		for i=#a,1,-1 do
			v[i] = {a[i], b[i]}
		end
		return v
	end;

	['zip1'] = function(a)
		local a,b = a[1],a[2]
		local v = {}
		for i=#a,1,-1 do
			v[i] = {a[i], b}
		end
		return v
	end;

	['rzip1'] = function(a)
		local a,b = a[1],a[2]
		local v = {}
		for i=#b,1,-1 do
			v[i] = {a, b[i]}
		end
		return v
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
	['cossin'] = function (a)
		return {f=',', math.cos(a), math.sin(a)}
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

	-- while loop
	['zolang'] = function(a)
		local init,cond,update = a[1],a[2],a[3]
		local x = init
		while cond(x) do
			x = update(x)
		end
		return x
	end;

	['schrijf'] = function(a) io.write(ansi.wisregel, ansi.regelbegin) ; io.write(a, '  '); io.flush() ; return a ; end;

	['tekst'] = lenc,

	['getal'] = function(a)
		return tonumber(string.char(table.unpack(a)))
	end;

	['afrond.onder'] = math.floor;
	['afrond.boven'] = math.ceil;
	['afrond'] = function(a) return math.floor(a+0.5) end;

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
		else return c end
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

	['willekeurig'] = function(t)
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
