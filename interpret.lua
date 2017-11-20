local insert = table.insert
local concat = table.concat

function clone(sexp)
	if atom(sexp) then
		return sexp
	else
		local res = {}
		for i,v in ipairs(sexp) do
			res[i] = clone(v)
		end
		return res
	end
end

local op
op = {
	['+'] = function (a,b) return a + b end;
	['-'] = function (a,b) if not b then return -a else return a - b end end;
	['*'] = function (a,b) return a * b end;
	['/'] = function (a,b) return b~=0 and a / b or 'oo' end;
	['^'] = function (a,b) if b then return a ^ b else return math.exp(a) end end;
	['_'] = function (a,b) if b then return math.log(a) / math.log(b) else return math.log(a) end end;

	['>'] = function (a,b) return a > b end;
	['<'] = function (a,b) return a < b end;
	['>='] = function (a,b) return a >= b end;
	['=<'] = function (a,b) return a <= b end;
	['='] = function (a,b)
		if type(a) == 'table' and type(b) == 'table' then
			if #a ~= #b then return false end
			for i,v in ipairs(a) do
				if not op['='](v,b[i]) then
					return false
				end
			end
			return true
		else
			return a == b
		end
	end;
	['%'] = function (a,b) return a % b end;

	['sin'] = math.sin;
	['cos'] = math.cos;
	['tan'] = math.tan;
	['asin'] = math.asin;
	['acos'] = math.acos;
	['atan'] = math.atan;
	['sqrt'] = function(a) if a < 0 then error('imaginaire getallen? nee nog niet') else return math.sqrt(a) end end;
	['cbrt'] = function (a) return math.pow(a, 1/3) end;

	['and'] = function (a,b) return a and b end;
	['or'] = function (a,b) return a and b end;
	['xor'] = function (a,b) return a ~= b end;
	['nor'] = function (a,b) return not a and not b end;

	['+-'] = function (a,b) error('opties nog niet ondersteund') end;
	['|'] = function (a,b) error('opties nog niet ondersteund') end;

	['#'] = function(a) return #a end;
	['..'] = function(a,b)
		local res = {}
		for i=a,b-1 do
			insert(res, i)
		end
		return res
	end;
	[','] = function(a,b)
		if type(a) == 'table' then
			local a = clone(a)
			insert(a,b)
			return a
		else
			return {a,b}
		end
	end;

	['||'] = function(a,b) return a .. b end;

	['.'] = function(a,b)
		if type(a) == 'table' and type(b) == 'number' then
			return a[b+1]
		end
		if type(a) == 'string' and type(b) == 'number' then
			return a:sub(b+1,b+1)
		end
		local res = {}
		for i,v in ipairs(b) do
			if type(a) == 'string' then
				insert(res, a:sub(v+1,v+1))
			elseif type(a) == 'number' then
				return 'index-dot'
			else
				insert(res, a[v+1])
			end
		end
		if type(a) == 'string' then
			return concat(res)
		else
			return res
		end
	end;

	['concat'] = concat;
	['find'] = function(a)
		local str,sub = unpack(a)
		local pos = find(str, sub, 0, true)
		if not pos then
			return false
		end
		return pos - 1
	end;

	['>>'] = function(a,b)
		if b == 'text' then
			return totext(a)
		end
	end;

	['=>'] = function(a,b)
		if a then
			return b
		else
			return false
		end
	end;

	['prog'] = function(a)
		return unparseProg(a)
	end;

	[':'] = function(val,group)
		if group == 'int' then
			return type(val) == 'number' and val%1==0
		else
			return false
		end
	end;

}

function interpret(prog)
	-- bevat echte waarden
	local res = {}
	for i,v in ipairs(prog) do
		if atom(v) then
			res[i] = v
		else
			local args = {}
			local fn
			fn = op[v[1]]
			if not fn then error('onbekende functie '..v[1]) end
			for i=2,#v do
				local src = v[i]
				local arg
				if isnumber(src) then
					arg = tonumber(src)
				elseif src == 'true' then
					arg = true
				elseif src == 'false' then
					arg = false
				elseif src == 'none' then
					arg = nil
				elseif src == 'tau' then
					arg = math.pi * 2
				elseif istext(src) then
					arg = gettext(src)
				elseif src == 'int' or src == 'text' then
					arg = src
				else
					local index = tonumber(src:sub(2))
					if not index then
						error('onbekende naam '..src)
					end
					arg = res[index + 1]
					if not arg then
						--break
						--error('ongeldige variabele '..src)
					end
				end
				insert(args,arg)
			end
			local ret 
			if false and v[1] ~= ',' and v[1] ~= '#'  and type(args[1]) == 'table' then
				local sargs = clone(args)
				ret = {}
				for i,v in ipairs(args[1]) do
					sargs[1] = v
					log('fn',sargs)

					ret[i] = fn(table.unpack(sargs))
				end
			else
				ret = fn(table.unpack(args))
			end
			res[i] = ret
		end
	end

	return res[#prog], res
end
