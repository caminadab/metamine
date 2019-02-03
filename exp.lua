function isfn(exp)
	return type(exp) == 'table' and exp.fn
end
function isatoom(exp)
	return type(exp) == 'string'
end

expmt = {}

function expmt:__tostring()
	local params = {}
	for k,param in pairs(self) do
		if type(param) == 'function' then
			param = 'FUNC'
		end
		params[k] = tostring(param)
	end
	-- =(a,b)

	local fn
	if isfn(self.fn) then
		fn = '('..tostring(params.fn)..')'
	else
		fn = tostring(params.fn)
	end
	local sep,lsep = ' ',''
	if #params > 3 then sep,lsep = '\n  ','\n' end
	return fn..'('..sep..table.concat(params,sep)..lsep..')'
end

function expmt:__eq(ander)
	local zelf = self
	if isatoom(zelf) ~= isatoom(ander) then return false end
	if isatoom(zelf) then return zelf == ander end
	if zelf.fn ~= ander.fn then return false end
	if #zelf ~= #ander then return false end
	for i=1,#zelf do
		if zelf[i] ~= ander[i] then
			return false
		end
	end
	return true
end

function bevat(exp, naam)
	if isatoom(exp) then
		return exp == naam
	else
		for i,v in pairs(exp) do
			if bevat(v,naam) then return true end
		end
		return false
	end
end

function toexp(exp)
	if type(exp) ~= 'table' then return exp end
	-- a()
	-- 2 ((+) ∘ (*)) 3
	-- (∘(+ *))(3,2)
	-- f(3)
	-- (3 * 2) + ((3))
	local exp2 = {}
	setmetatable(exp2,expmt)
	for k,v in pairs(exp) do exp2[k] = toexp(v) end
	return exp2
end

function maakfn(naam,...)
	local exp
	if type(naam) == 'table' then
		exp = naam
	else
		exp = { fn = naam, ... }
	end

	setmetatable(exp, expmt)
	return exp
end

function maakeq(l,r)
	local eq = {type='eq',fn='=',l,r}
	setmetatable(eq, {
		__tostring = function(zelf)
			return tostring(zelf[1])..' = '..tostring(zelf[2])
		end;
		__eq = expmt.__eq;
	})
	return eq
end


if test then
	local a = toexp {fn = '+', 'a', '2'}
	assert(bevat(a, 'a'))
end
