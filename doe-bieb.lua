require 'exp'

bieb = {
	['tau'] = 2 * math.pi;
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
		local s = {is_set=true}
		for _,v in pairs(t) do
			s[v] = true
		end
		return s
	end,
	['ontleed'] = function(a)
		local code = string.char(table.unpack(a))
		local data = ontleed(code)
	end;

	['_'] = function(...)
		return function(a) return a

	['@'] = function(a,b)
		assert(type(a) == 'function')
		assert(type(b) == 'function')
		return function(...)
			return b(a(...))
		end
	end;

	['|'] = function(a,b)
		local fa = type(a) == 'function'
		local fb = type(b) == 'function'
		if fa ~= fb then return 'fout' end
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
		return a or b
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
		local j = 1
		local t = {}
		if isatoom(a) then a = {a} end
		if isatoom(b) then b = {b} end
		for i,v in ipairs(a) do t[j] = v; j=j+1 end
		for i,v in ipairs(b) do t[j] = v; j=j+1 end
		return t
	end;

	-- lib
	['cat'] = function(a,b)
		local r = {}
		for i,v in ipairs(a) do
			for i,v in ipairs(v) do
				r[#r+1] = v
			end
			if b then
				r[#r+1] = b
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

	['of'] = function(a,b) return a or b end;
	['en'] = function(a,b) return a and b end;

	['som'] = function(a)
		local r = 0
		for i,v in ipairs(a) do
			r = r + v
		end
		return r
	end;

	['herhaal'] = function(a,n) -- 10
		local r = {}
		for i=1,n do
			r[i] = a
		end
		return r
	end;

	['tekst'] = function(a)
		if type(a) == 'table' then
			a = tostring(toexp(a))
		end
		return table.pack(string.byte(tostring(a),1,#tostring(a)))
	end;

	['getal'] = function(a)
		return tonumber(string.char(table.unpack(a)))
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

	['verschil'] = function(a,b)
		local s = {}
		for k,v in pairs(a) do if not b[k] then s[k] = v end end
		return s
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
	['kan-lezen'] = function(b)
		if not b.buf then b.buf = b.fd:read(1024) end
		return b.buf
	end;
	['lees'] = function(b)
		local buf = b.buf
		b.buf = nil
		return buf
	end;
	['=>'] = function(a,b)
		if a then return b
		else return nil end
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
}
