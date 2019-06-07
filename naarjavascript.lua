require 'util'
require 'exp'

local infix = set('+', '-', '*', '/', '!=', '=', '>', '<', '/\\', '\\/', 'mod')
local tab = '    '
local bieb = {['@'] = '_comp', ['|'] = '_kies', ['!'] = 'not', ['^'] = '_pow', [':'] = '_istype',
	['%'] = '_procent', ['..'] = '_iinterval'};
local function naarjavascriptR(exp,t,tabs,maakvar)
	if tonumber(exp) then return tostring(exp) end
	if isatoom(exp) then
		return exp.v,t
	end
	if not exp.fn then return '0' end

	local fn,a,b = exp.fn.v, exp[1], exp[2]
	local var = maakvar()

	if infix[fn] then
		if fn == '=' then fn = '===' end
		if fn == '!=' then fn = '!==' end
		if fn == '+i' then fn = '+i' end
		if fn == '/\\' then fn = '&&' end
		if fn == '\\/' then fn = '||' end
		if fn == 'mod' then fn = '%' end
		local A = naarjavascriptR(a,t,tabs,maakvar)
		local B = naarjavascriptR(b,t,tabs,maakvar)
		t[#t+1] = string.format('%s%s = %s %s %s;\n', tabs, var, A, fn, B)

	elseif fn == '||' then
		local A = naarjavascriptR(a,t,tabs,maakvar)
		local B = naarjavascriptR(b,t,tabs,maakvar)
		t[#t+1] = string.format('%s%s = cat([%s, %s]);\n', tabs, var, A, B)

	elseif fn == '=>' then
		local A = naarjavascriptR(a,t,tabs,maakvar)
		t[#t+1] = string.format('%svar %s = false;\n', tabs, var)
		t[#t+1] = string.format('%sif (%s) {\n', tabs, A)
		local B = naarjavascriptR(b,t,tabs..tab,maakvar)
		t[#t+1] = string.format('%s%s = %s;\n', tabs..tab, var, B)
		t[#t+1] = string.format('%s}\n', tabs)

	elseif fn == '[]' or fn == ',' then
		local vars = {}
		for i,v in ipairs(exp) do
			vars[i] = naarjavascriptR(v,t,tabs,maakvar)
		end
		inhoud = table.concat(vars, ',')
		t[#t+1] = string.format('%svar %s = [%s];\n', tabs, var, inhoud)

	elseif fn == 'map' then
		-- nieuw
		local nieuw = var
		t[#t+1] = string.format('%svar %s = [];\n', tabs, nieuw)

		local A = naarjavascriptR(a,t,tabs,maakvar)

		-- mappen
		local sub = string.format('%s(%s[i])', naarjavascriptR(b,t,tabs,maakvar), A)

		-- lus
		t[#t+1] = string.format('%sfor (var i = 0; i < %s.length; i++) {\n',tabs,A)
		local tabs1 = tabs .. tab

		-- terugzetten
		t[#t+1] = string.format('%s%s[i] = %s\n',tabs1,nieuw,sub)
		t[#t+1] = tabs..'}\n'

	elseif fn == '->' then
		t[#t+1] = string.format('%svar %s = function (%s) {\n', tabs, var, a.v)
		local res = naarjavascriptR(b, t, tabs..tab, maakvar)
		t[#t+1] = string.format('%sreturn %s;\n', tabs..tab, res)
		t[#t+1] = string.format('%s}\n', tabs)

	elseif true then
		-- normale functie aanroep
		local vars = {}
		for k,v in pairs(exp) do
			vars[k] = naarjavascriptR(v,t,tabs,maakvar)
		end
		if bieb[fn] then vars.fn = bieb[fn] end
		inhoud = table.concat(vars, ',')
		t[#t+1] = string.format('%svar %s = _I(%s, %s);\n', tabs, var, vars.fn, inhoud)

	else
		print('???', toexp(exp))

	end

	return var,t
end

-- biebbron zit in de weg, "javascript X" functie zit in de weg (global scope in expressie?)
function naarjavascript(exp)
	local t = {}

	-- bieb
	for naam in boompairs(exp) do
		if isatoom(naam) and jsbieb[atoom(naam)] then
			gebruikt[naam.v] = true
		end
	end
	for naam in spairs(gebruikt) do
		t[#t+1] = jsbieb[naam]
	end

	t[#t+1] = "nu = new Date().getTime() / 1000;\nlooptijd = nu - start;\n"
	local var,t = naarjavascriptR(exp,t,tab,maakvars())
	t[#t+1] = "\n"
	--t[#t+1] = tab..'document.getElementById("uittekst").innerHTML = ' .. var .. ";\n"
	t[#t+1] = tab..'A = ' .. var .. ";\n"
	t[#t+1] = 'if (Array.isArray(A))'
	t[#t+1] = 'A = arr2str(A);'
	local lua = table.concat(t)
	return lua
end
