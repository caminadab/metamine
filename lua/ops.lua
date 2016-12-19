
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

local add = op2('+')
local sub = op2('-')
local mul = op2('*')
local div = op2('/')
local mod = op2('%')
local pow = op2('^')
local unm = op1('-')
local concat = op2('..')
local len = op1('#')
local eq = op2('==')
local lt = op2('<')
local le = op2('<=')

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


return ops