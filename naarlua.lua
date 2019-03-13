require 'util'
require 'exp'

-- 1-gebaseerd
-- 1 t/m 26 zijn A t/m Z
-- daarna AA t/m ZZ
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

local infix = set('+', '-', '*', '/', '!=') 
local tab = '    '
local bieb = {['@'] = '_comp', ['|'] = '_kies', ['!'] = 'not', ['^'] = '_pow'}
local function naarluaR(exp,t,tabs,maakvar)
	if isatoom(exp) then
		return exp
	end

	local fn,a,b = exp.fn, exp[1], exp[2]
	local var = maakvar()

	if infix[fn] then
		if fn == '=' then fn = '==' end
		if fn == '!=' then fn = '~=' end
		local A = naarluaR(a,t,tabs,maakvar)
		local B = naarluaR(b,t,tabs,maakvar)
		t[#t+1] = string.format('%slocal %s = %s %s %s\n', tabs, var, A, fn, B)

	elseif fn == '||' then
		local A = naarluaR(a,t,tabs,maakvar)
		local B = naarluaR(b,t,tabs,maakvar)
		t[#t+1] = string.format('%slocal %s = cat{%s, %s}\n', tabs, var, A, B)

	elseif fn == '=>' then
		local A = naarluaR(a,t,tabs,maakvar)
		t[#t+1] = string.format('%slocal %s = false\n', tabs, var)
		t[#t+1] = string.format('%sif %s then\n', tabs, A)
		local B = naarluaR(b,t,tabs..tab,maakvar)
		t[#t+1] = string.format('%s%s = %s\n', tabs..tab, var, B)
		t[#t+1] = string.format('%send\n', tabs)

	elseif fn == '[]' then
		local vars = {}
		for i,v in ipairs(exp) do
			vars[i] = naarluaR(v,t,tabs,maakvar)
		end
		inhoud = table.concat(vars, ',')
		t[#t+1] = string.format('%slocal %s = tabel{%s}\n', tabs, var, inhoud)

	elseif fn == 'map' then
		-- nieuw
		local nieuw = var
		t[#t+1] = string.format('%slocal %s = tabel{}\n', tabs, nieuw)

		local A = naarluaR(a,t,tabs,maakvar)

		-- mappen
		local sub = string.format('%s(%s[i])', naarluaR(b,t,tabs,maakvar), A)

		-- lus
		t[#t+1] = string.format('%sfor i=1,#%s do\n',tabs,A)
		local tabs1 = tabs .. tab

		-- terugzetten
		t[#t+1] = string.format('%s%s[i] = %s\n',tabs1,nieuw,sub)
		t[#t+1] = tabs..'end\n'

	elseif fn == '->' then
		t[#t+1] = string.format('%slocal %s = function (%s)\n', tabs, var, a)
		local res = naarluaR(b, t, tabs..tab, maakvar)
		t[#t+1] = string.format('%sreturn %s\n', tabs..tab, res)
		t[#t+1] = string.format('%send\n', tabs)

	elseif true then
		-- normale functie aanroep
		local vars = {}
		for k,v in pairs(exp) do
			vars[k] = naarluaR(v,t,tabs,maakvar)
		end
		if bieb[fn] then vars.fn = bieb[fn] end
		inhoud = table.concat(vars, ',')
		t[#t+1] = string.format('%slocal %s = %s(%s)\n', tabs, var, vars.fn, inhoud)

	else
		print('???', toexp(exp))

	end

	return var,t
end

local biebbron = [[
local unpack = unpack or table.unpack
local _pow = function(a,b)
	if type(a) == 'number' then
		return a ^ b
	else
		return function(c)
			for i=1,b do
				c = a(c)
			end
			return c
		end
	end
end
local _comp = function(a,b)
	return function(...)
		return b(a(...))
	end
end
local tabel = function(t)
	local t = t or {}
	local mt = {}
	function mt:__call(i)
		return t[i+1]
	end
	setmetatable(t, mt)
	return t
end
local vanaf = function(a,van)
	local t = tabel{}
	for i=van+1,#a do
		t[#t+1] = a[i]
	end
	return t
end

local tot = function(a,tot)
	local t = tabel{}
	for i=1,tot do
		t[#t+1] = a[i]
	end
	return t
end

local deel = function(a,b)
	local van,tot = b[1],b[2]
	local t = tabel{}
	for i=van+1,tot do
		t[#t+1] = a[i]
	end
	return t
end

local _kies = function(a,b)
	local fa = type(a) == 'function'
	local fb = type(b) == 'function'
	if a and b then return 'fout' end
	return a or b
end

local cat = function(a,b)
	local r = tabel{}
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
end
]]
local biebbron = biebbron:gsub('\t', tab)

function naarlua(exp)
	local t = {biebbron}
	local var,t = naarluaR(exp,t,'',maakvars())
	t[#t+1] = 'print(string.char(unpack('..var..')))\n'
	local lua = table.concat(t)
	return lua
end
