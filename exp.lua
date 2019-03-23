require 'lisp'

expmt = {}

function exp2string(self,tabs)
	if type(self) ~= 'table' then return '???' end --error('is geen expressie') end
	if not self.v and not self.fn then error('is geen expressie') end

	do return unlisp(self) end
	if type(self) == 'string' then return self end
	local tabs = (tabs or '') .. '  '
	local params = {}
	local len = 2 -- '(' & ')'
	for k,param in pairs(self) do
		if type(param) == 'function' then
			param = 'FUNC'
		end
		params[k] = tostring(param,tabs..'  ')
		len = len + #params[k] + 1 -- ' '
	end
	-- =(a,b)

	local fn
	if isfn(self) then
		fn = '('..expmt.__tostring(params.fn,tabs..'  ')..')'
	else
		fn = tostring(params.fn)
	end
	if len > 30 then
		return fn .. '\n' .. tabs .. table.concat(params, '\n'..tabs)
	else
		return fn..'('..table.concat(params,sep)..')'
	end
end

expmt.__tostring = exp2string

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
	if not exp then error('geen exp') end
	if not exp.v and not exp.fn then error('geen exp') end
	if not naam.v then error('naam is geen exp') end

	if exp.v then
		return exp.v == naam.v
	else
		if bevat(exp.fn, naam) then return true end
		for i,v in ipairs(exp) do
			if bevat(v, naam) then return true end
		end
		return false
	end
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

function T(tabs)
	do return unlisp(self) end
	if type(self) == 'string' then return self end
	local tabs = (tabs or '') .. '  '
	local params = {}
	local len = 2 -- '(' & ')'
	for k,param in pairs(self) do
		if type(param) == 'function' then
			param = 'FUNC'
		end
		params[k] = tostring(param,tabs..'  ')
		len = len + #params[k] + 1 -- ' '
	end
	-- =(a,b)

	local fn
	if isfn(self.fn) then
		fn = '('..expmt.__tostring(params.fn,tabs..'  ')..')'
	else
		fn = tostring(params.fn)
	end
	if len > 30 then
		return fn .. '\n' .. tabs .. table.concat(params, '\n'..tabs)
	else
		return fn..'('..table.concat(params,sep)..')'
	end
end

if test then
	-- bevat
	local a = X('+', 'a', '2')
	assert(bevat(a, X'a'), exp2string(a))
end
