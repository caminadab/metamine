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

local infix = set('+', '-', '*', '/', '!=', '=', '>', '<', '/\\', '\\/', 'mod')
local tab = '    '
local bieb = {['@'] = '_comp', ['|'] = '_kies', ['!'] = 'not', ['^'] = '_pow', [':'] = '_istype', ['%'] = '_procent'};
local function naarjavascriptR(exp,t,tabs,maakvar)
	if isatoom(exp) then
		return exp.v,t
	end

	local fn,a,b = exp.fn.v, exp[1], exp[2]
	local var = maakvar()

	if infix[fn] then
		if fn == '=' then fn = '===' end
		if fn == '!=' then fn = '!==' end
		if fn == '/\\' then fn = '&&' end
		if fn == '\\/' then fn = '||' end
		if fn == 'mod' then fn = '%' end
		local A = naarjavascriptR(a,t,tabs,maakvar)
		local B = naarjavascriptR(b,t,tabs,maakvar)
		t[#t+1] = string.format('%svar %s = %s %s %s;\n', tabs, var, A, fn, B)

	elseif fn == '||' then
		local A = naarjavascriptR(a,t,tabs,maakvar)
		local B = naarjavascriptR(b,t,tabs,maakvar)
		t[#t+1] = string.format('%svar %s = cat([%s, %s]);\n', tabs, var, A, B)

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
		t[#t+1] = string.format('%sfor (var i = 1; i < %s.length; i++) {\n',tabs,A)
		local tabs1 = tabs .. tab

		-- terugzetten
		t[#t+1] = string.format('%s%s[i] = %s\n',tabs1,nieuw,sub)
		t[#t+1] = tabs..'end\n'

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

javascriptbieb = [[
tau = Math.PI * 2;
start = new Date().getTime() / 1000;

/*
local ja = true
local nee = false
local pack = pack or table.pack
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
local lijst = 'lijst'
local int = 'int'
local getal = 'getal'
local _istype = function(a,b)
	if b == getal then return type(a) == 'number' end
	if b == int then return type(a) == 'number' and a%1 == 0 end
	if b == lijst then return type(a) == 'table' end
	return false
end
*/
var _comp = function(a,b) {
	return function() {
		return b(a(arguments))
	};
};

function _I(a,i,...args) {
	if (Array.isArray(a))
		return a[i];
	else {
		//var args = [];
		//for (var i = 1; i < arguments.length; i++)
			//args.push( arguments[i] );
		//return a.apply(a, args);
		return a(i,...args);
	}
}

function vanaf(a,van) {
	return a.splice(van,a.length);
}

function tot(a,tot) {
	return a.splice(0,tot);
}

function deel(a,b) {
	return a.splice(b[0],b[1]);
}
/*
function tabel(t)
	var t = t || {}
	local mt = {}
	function mt:__call(i)
		return t[i+1]
	end
	setmetatable(t, mt)
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

local vind = function(a,b)
	for i=1,#a-#b+1 do
		local gevonden = true
		for j=i,i+#b-1 do
			if a[j] ~= b[j-i+1] then
				gevonden = false
				break
			end
		end
		if gevonden then
			return i-1
		end
	end
	return false
end

local tekst = function (a)
	local t = tostring(a)
	return {string.byte(t,1,#t)}
end

local herhaal = function(f)
	return function(a)
		local r = a
		while a do
			r = a
			a = f(a)
		end
		return r
	end
end
*/

var _procent = function(a) { return a / 100; }

var sin = Math.sin;
var cos = Math.cos;
var tan = Math.tan;
var int = Math.floor;
var abs = Math.abs;

]]
javascriptbieb = javascriptbieb:gsub('\t', tab)

-- biebbron zit in de weg, "javascript X" functie zit in de weg (global scope in expressie?)
function naarjavascript(exp)
	local t = {}
	t[#t+1] = "(function() {\n"..tab.."nu = new Date().getTime() / 1000;\nlooptijd = nu - start;\n"
	local var,t = naarjavascriptR(exp,t,tab,maakvars())
	t[#t+1] = "\n"
	t[#t+1] = tab.."return " .. var .. ";\n"
	t[#t+1] = "})()\n"
	local lua = table.concat(t)
	return lua
end
