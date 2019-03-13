require 'util'
require 'exp'

-- 1-gebaseerd
-- 1 t/m 26 zijn A t/m Z
-- daarna AA t/m ZZ
local function varnaam(i)
	local l = string.char(string.byte('A') + ((i-1)%26))
	local h = string.char(string.byte('A') + ((i-1)/26) - 1)
	if i <= 26 then
		return l
	else
		return h .. l
	end
end

function maakvars()
	local i = 1
	return function ()
		local var = varnaam(i)
		i = i + 1
		return var
	end
end

local infix = set('+', '-', '*', '/') 
local tab = '    '
local function naarluaR(exp,t,tabs,maakvar)
	if isatoom(exp) then
		return exp
	end

	local fn,a,b = exp.fn, exp[1], exp[2]
	local var = maakvar()

	if infix[fn] then
		local A = naarluaR(a,t,tabs,maakvar)
		local B = naarluaR(b,t,tabs,maakvar)
		t[#t+1] = string.format('%slocal %s = %s %s %s\n', tabs, var, A, fn, B)

	elseif fn == '[]' then
		local vars = {}
		for i,v in ipairs(exp) do
			vars[i] = naarluaR(v,t,tabs,maakvar)
		end
		inhoud = table.concat(vars, ',')
		t[#t+1] = string.format('%slocal %s = {%s}\n', tabs, var, inhoud)

	elseif fn == 'map' then
		-- nieuw
		local nieuw = var
		t[#t+1] = string.format('%slocal %s = {}\n', tabs, nieuw)

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
		inhoud = table.concat(vars, ',')
		t[#t+1] = string.format('%slocal %s = %s(%s)\n', tabs, var, vars.fn, inhoud)

	else
		print('???', toexp(exp))

	end

	return var,t
end

local bieb = [[
local cat = function(a,b)
	local r = {fn='[]'}
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
local bieb = bieb:gsub('\t', tab)

function naarlua(exp)
	local t = {bieb}
	local var,t = naarluaR(exp,t,'',maakvars())
	t[#t+1] = 'print(string.char(table.unpack('..var..')))\n'
	local lua = table.concat(t)
	return lua
end
