--[[
exp = { fn, 1, 2 } | { v }
exp |= { loc, val }
]]
require 'lisp'

expmt = {}

function loctekst(loc)
	local bron = loc.bron or '?'
	if loc.y1 == loc.y2 and loc.x1 == loc.x2 then
		return string.format("%s@%d:%d", bron, loc.y1, loc.x1)
	elseif loc.y1 == loc.y2 then
		return string.format("%s@%d:%d-%d", bron, loc.y1, loc.x1, loc.x2)
	else
		return string.format("%s@%d:%d-%d:%d", bron, loc.y1, loc.x1, loc.y2, loc.x2)
	end
end

function expmoesR(exp, t)
	if isatoom(exp) then t[#t+1] = exp.v
	else
		if not isatoom(exp.fn) then t[#t+1] = '(' end
		expmoesR(exp.fn, t)
		if not isatoom(exp.fn) then t[#t+1] = ')' end
		t[#t+1] = '('
		for i, v in ipairs(exp) do
			expmoesR(v, t)
			if i ~= #exp then t[#t+1] = ' ' end
		end
		t[#t+1] = ')'
	end
end

function expmoes(exp)
	local t = {}
	expmoesR(exp, t)
	return table.concat(t)
end
moes = expmoes

-- 1-gebaseerd
-- 1 t/m 26 zijn A t/m Z
-- daarna AA t/m ZZ
-- daarna AAA t/m ZZZ
function varnaam(i)
	local r = ''
	i = i - 1
	repeat
		local c = i % 26
		i = math.floor(i / 26)
		local l = string.char(string.byte('A') + c)
		r = r .. l
	until i == 0
	return r
end

function maakvars()
	local i = 1
	return function ()
		local var = varnaam(i)
		i = i + 1
		return var
	end
end

-- willekeurige volgorde
function boompairs(exp)
	local t = {}
	function r(exp)
		if isatoom(exp) then
			t[exp] = true
		else
			t[exp] = true
			r(exp.fn)
			for i,v in ipairs(exp) do
				r(v)
			end
		end
	end
	r(exp)
	
	local k = nil
	return function()
		if next(t,k) then
			k = next(t,k)
			return k
		end
	end
end

-- depth first search
function boompairsdfs(exp)
	local t = {}
	function r(exp)
		if isatoom(exp) then
			t[#t+1] = exp
		else
			r(exp.fn)
			for i,v in ipairs(exp) do
				r(v)
			end
			t[#t+1] = exp
		end
	end
	r(exp)
	
	local i = 1
	return function()
		i = i + 1
		return t[i-1]
	end
end

-- breadth first search
function boompairsbfs(exp)
	local t = {}
	function r(exp)
		if isatoom(exp) then
			t[#t+1] = exp
		else
			t[#t+1] = exp
			r(exp.fn)
			for i,v in ipairs(exp) do
				r(v)
			end
		end
	end
	r(exp)
	
	local i = 1
	return function()
		i = i + 1
		return t[i-1]
	end
end

function exp2string(self,tabs)
	if type(self) ~= 'table' then return error('is geen expressie') end
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
	do
		return self:moes() == ander:moes()
	end

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
