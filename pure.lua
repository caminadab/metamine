require 'util'

local builtin = {
	-- constants
	['false'] = false;
	['true'] = true;
	['tau'] = 2 * math.pi;

	-- arith
	['+'] = function (...)
		local res = 0
		for i,n in ipairs({...}) do
			res = res + n
		end
		return res
	end;
	['-'] = function (a,...)
		local res = a
		for i,n in ipairs({...}) do
			res = res - n
		end
		return res
	end;
	['*'] = function (...)
		local res = 1
		for i,n in ipairs({...}) do
			res = res * n
		end
		return res
	end;
	['/'] = function (a,...)
		local res = a
		for i,n in ipairs({...}) do
			res = res / n
		end
		return res
	end;
	['^'] = function (a, b) return a ^ b end;
	['%'] = function (a, b) return a % b end;

	-- math
	atan = math.atan2;
	sin = math.sin;
	cos = math.cos;
	tan = math.tan;
	abs = math.abs;
	sqrt = math.sqrt;
	round = math.round;
	floor = math.floor;
	ceil = math.ceil;
	max = math.max;
	min = math.min;

	-- logic
	['if'] = function (cond, thn, els)
		if cond=='true' then
			return thn
		elseif cond=='false' then
			return els
		else
			error('no')
		end
	end;
	['and'] = function (a, b) return a and b end;
	['or'] = function (a, b) return a or b end;
	['xor'] = function (a, b) return a ~= b end;
	['not'] = function (a) return not a end;
	['<'] = function (a, b) return a < b end;
	['<='] = function (a, b) return math.abs(a,b) < 0.1 or a < b end;
	['>'] = function (a, b) return tonumber(a) > tonumber(b) end;
	['>='] = function (a, b) return math.abs(a,b) < 0.1 or tonumber(a) > tonumber(b) end;
	['='] = function (a, b) return math.abs(a-b) < 0.1 end;

	-- meta
	['..'] = function (a,b)
		if a == b then return a
		elseif a > b then return 'undefined'
		else
			local res = {','}
			for i=a,b-1 do
				table.insert(res, tostring(i))
			end
			return res
		end
	end;
	['to'] = function (a,b)
		if a == b then return a
		elseif a > b then return 'undefined'
		else return {'to',a,b} end
	end;
	['|'] = function (...)
		local uniq = {}
		for i,v in ipairs({...}) do
			uniq[v] = true
		end
		local res = {'|'}
		for v in pairs(uniq) do
			table.insert(res, v)
		end
		return res
	end;
	['+-'] = function (a)
		return {'|',a,-a}
	end;
	
	-- text
	['||'] = function (...) return table.concat({...}) end;
	['#'] = function (text) return #text end;
	['hex'] = hex_encode;
	['ntoh'] = ntoh;
	['hton'] = function (text) return hton(text, 4) end;
}

if not table.unpack then
	table.unpack = function(table)
		return table[1], table[2], table[3], table[4]
	end
end

function evalPure(sexp)
	if exp(sexp) then
		-- subs
		local args = tail(sexp)
		if #args==1 and exp(args[1]) then
			args = args[1]
		end
		
		-- maak parameters
		local newargs = {}
		for i,arg in ipairs(args) do
			if atom(arg) then
				newargs[i] = tolua(arg)
			else
				newargs[i] = true
			end
		end
		
		-- nu laat ons gaan
		local builtin = builtin[head(sexp)]
		local ok,res = pcall(builtin, table.unpack(newargs))
		if ok then
			if type(res)=='table' then
				end
			return tolisp(res)
		else
			return sexp
		end
	else
		return sexp
	end
end
