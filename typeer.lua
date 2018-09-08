require 'symbool'
require 'func'
require 'util'
require 'lisp'

local prios = {
	['^'] = 4, ['_'] = 4,
	['*'] = 3, ['/'] = 3,
	['+'] = 2, ['-'] = 2,
	['='] = 1,
	[':='] = 0,
}

local function issimpel(t)
	return isatoom(t) and (t == 'bit' or t == 'getal' or t == 'int')
end
local function issimpel1(t)
	return isexp(t) and t[1] == '->' and issimpel(t[2]) and issimpel(t[3])
end
assert(issimpel1{'->', 'getal', 'getal'})

local function issimpel2(t)
	if not isexp(t) then return false end
	local argn = t[2]
	local bi = isexp(argn) and #argn == 3 and issimpel(argn[2]) and issimpel(argn[3])
	return isexp(t) and t[1] == '->' and bi
end

local dichtbij = {['^']=true,['_']=true,['.']=true,['..']=true}
local op = {['^']=true,['_']=true,['*']=true,['/']=true,['+']=true,['-']=true,["'"]=true}

function leedwerk(exp, t, arg)
	local prio = 0
	if isatoom(exp) then
		if arg and op[exp] then
			t[#t+1] = '('
			t[#t+1] = exp
			t[#t+1] = ')'
		else
			t[#t+1] = exp
		end
	elseif exp[1] == '{}' then
		t[#t+1] = '{'
		for i=2,#exp do
			leedwerk(exp[i], t)
			if next(exp,i) then
				t[#t+1] = ','
			end
		end
		t[#t+1] = '}'

	-- postfix
	elseif exp[1] == "'" or exp[1] == '%' then
		leedwerk(exp[2], t)
		t[#t+1] = exp[1]
	elseif exp[1] == '[]' then
		t[#t+1] = '['
		for i=2,#exp do
			leedwerk(exp[i], t)
			if next(exp,i) then
				t[#t+1] = ','
			end
		end
		t[#t+1] = ']'
	elseif #exp == 2 then
		leedwerk(exp[1], t)
		t[#t+1] = ' '
		leedwerk(exp[2], t, true)
	elseif #exp == 3 then
		leedwerk(exp[2], t, true)
		if not dichtbij[exp[1]] then t[#t+1] = ' ' end
		leedwerk(exp[1], t)
		if not dichtbij[exp[1]] then t[#t+1] = ' ' end
		leedwerk(exp[3], t, true)
	end
	return t
end

function leed(exp)
	local exp = exp or 'onbekend'
	local t = leedwerk(exp, {})
	t[#t+1] = color.white
	return table.concat(t)
end

local function verenig_of(ta, tb)
	if ta == 'fout' or tb == 'fout' then return 'fout' end
	if ta and not tb then return ta end
	if tb and not ta then return tb end
	if not ta and not tb then return nil end 
	if unlisp(ta) == unlisp(tb) then
		return ta
	end

	-- handmatige groepen
	if ta == 'int' and tb == 'getal' then return 'getal' end
	if tb == 'int' and ta == 'getal' then return 'getal' end

	-- deelmatch
	if isexp(ta) and isexp(tb) and #ta == #tb then
		local t = {}
		for i=1,#ta do
			local ti,fi = verenig_of(ta[i],tb[i])
			if ti == 'fout' then
				return ti,fi
			end
			t[i] = ti
		end
		return t
	end

	-- echte logica
	if tonumber(tb) then ta,tb = tb,ta end

	if tonumber(ta) and tonumber(tb) then
		local na = tonumber(ta)
		local nb = tonumber(tb)
		if math.floor(na) == na and math.floor(nb) == nb then
			return 'int'
		else
			return 'getal'
		end
	end

	if tonumber(ta) and (tb == 'getal' or tb == 'int') then
		return tb
	end

	return 'fout', leed(ta)..' != '..leed(tb)
end
assert(verenig_of('2', 'int') == 'int')
assert(verenig_of('2', '3') == 'int', verenig_of('2','3'))
assert(verenig_of('getal', '2') == 'getal')
assert(verenig_of('int', 'getal') == 'getal')

-- nil = onbekend, fout = fout
local function verenig_en(ta, tb)
	if ta == 'iets' then ta = nil end
	if tb == 'iets' then tb = nil end
	if ta and not tb then return ta end
	if tb and not ta then return tb end
	if not ta and not tb then return nil end 
	if ta == 'fout' or tb == 'fout' then return 'fout' end
	if unlisp(ta) == unlisp(tb) then
		return ta
	end

	-- handmatig
	if ta == 'getal' and tb == 'int' then return 'int' end
	if tb == 'getal' and ta == 'int' then return 'int' end

	-- deelmatch
	if isexp(ta) and isexp(tb) and #ta == #tb then
		local t = {}
		for i=1,#ta do
			local ti,fi = verenig_en(ta[i],tb[i])
			if ti == 'fout' then
				return ti,fi
			end
			t[i] = ti
		end
		return t
	end

	-- echte logica
	if tonumber(tb) then ta,tb = tb,ta end

	if tonumber(ta) and tonumber(tb) and ta ~= tb then
		return 'fout', leed(ta)..' != '..tb
	end
	if tonumber(ta) and (tb == 'getal' or tb == 'int') then
		return ta
	end

	return 'fout', leed(ta)..' != '..leed(tb)
end

assert(verenig_en('2', 'int') == '2')
assert(verenig_en('2', '3') == 'fout')
assert(verenig_en('int', 'getal') == 'int')
local varlijst = {'^', 'getal', 'int'}
local vastlijst = {'^', 'getal', '2'}
assert(unlisp(verenig_en(varlijst, vastlijst)) == '(^ getal 2)')

-- lengte of een lijst type
function lijstlen(t, typen)
	if isatoom(t) then return nil end
	if t[1] == '^' then return tostring(t[3]) or t[3] end --TEMP tostring
end

local function issimpelefunctie(t)
	return isexp(t) and t[1] == '->' and isatoom(t[2]) and isatoom(t[3])
end

-- gaat ervan uit dat typen.aantalOnbekend ingevuld is
-- exp,typen -> {exp -> type}
function exptypeer(exp, typen)
	typen.fouten = typen.fouten or {}
	local fouten = typen.fouten
	-- is al bekend?
	if typen[exp] then return typen[exp] end

	-- type, subtypen
	local t,T = nil,{}
	local f,F = nil,{}

	-- hulp
	local fn = isexp(exp) and exp[1]
	local a = isexp(exp) and exp[2]
	local b = isexp(exp) and exp[3]
	local tfn,ffn = fn and exptypeer(fn,typen)
	local ta,fa = a and exptypeer(a,typen)
	local tb,fb = b and exptypeer(b,typen)

	if isatoom(exp) then
		if tonumber(exp) then
			t = 'getal'
		else
			-- onbekend
		end

	-- direct type
	elseif exp[1] == ':' then
		local a,b = exp[2], exp[3]
		T[a] = b
		t = 'ok'

	-- dynamisch
	--elseif exp[1] == '=>' and ta == 'moment' then
		--t = tb or 'iets'

	-- functie
	elseif exp[1] == '->' then
		t = {'->', ta or 'iets', tb or 'iets'}

	-- of
	elseif exp[1] == '|' then
		t,f = verenig_en(ta,tb)

	-- schaduw
	elseif exp[1] == "'" then
		t,f = ta,tf

	-- interval
	elseif exp[1] == '..' then
		local a,b = exp[2], exp[3]
		T[a],F[a] = exptypeer(a,typen)
		T[b],F[b] = exptypeer(b,typen)
		if F[a] or F[b] then
			t = 'fout'
		end
		t = {'^', 'int', 'int'}

	-- vergelijking
	elseif exp[1] == '=' or exp[1] == ':=' then
		local a,b = exp[2], exp[3]
		local ta,fa = exptypeer(a, typen)
		local tb,fb = exptypeer(b, typen)
		local tab,fab = verenig_en(ta,tb)
		T[a] = tab
		T[b] = tab
		if tab and tab~='fout' then
			t = 'ok'
		elseif not tab then
			t = nil
		else
			t = 'fout'
			--print(fa,fb,fab)
			f = nil--fa or fb or fab or 'uhh'--leed(ta)..' != '..leed(tb)
			f = fab
		end

	-- predicaat dat alleen van tijd afhangt
	-- (tijd -> 
	-- a => b
	-- {a => 0, b => 1} is  T => getal

	-- sets
	-- [1,2,3] is int^3, {1,2,3} is  {int}
	elseif exp[1] == '{}' then
		local ti = nil
		for i=2,#exp do
			local a = exp[i]
			local ta = exptypeer(a, typen)
			ti = verenig_of(ti, ta)
		end
		if ti == 'fout' then
			t = 'fout'
			f = 'kon type van set niet bepalen'
		elseif not ti then
			t = nil
		else
			t = {'{}', ti}
		end

	-- lijsten
	elseif exp[1] == '[]' then
		local ti = nil
		for i=2,#exp do
			local a = exp[i]
			local ta = exptypeer(a, typen)
			ti = verenig_of(ti, ta)
		end
		if ti == 'fout' then
			t = 'fout'
			f = 'kon type van lijst niet bepalen'
		elseif not ti then
			t = nil
		else
			t = {'^', ti, #exp-1}
		end

	-- of, en, exof, noch
	elseif exp[1] == 'of' then
		local a,b = exp[2],exp[3]
		local ta,fa = exptypeer(a,typen)
		local tb,fb = exptypeer(b,typen)
		T[a],T[b] = ta,tb
		F[a],F[b] = fa,fb
		t,f = verenig_of(ta,tb)

	elseif exp[1] == 'niet' then
		t,f = verenig_en(ta,'bit')

	elseif exp[1] == '=>' then
		local a,b = exp[2],exp[3]
		t = exptypeer(b, typen)

	elseif exp[1] == '+=' then
		local a,b = exp[2],exp[3]
		exptypeer(a, typen)
		exptypeer(b, typen)
		T[a] = 'getal'
		T[b] = 'getal'
		t = 'ok'

	elseif exp[1] == ':=' then
		local a,b = exp[2],exp[3]
		exptypeer(a, typen)
		exptypeer(b, typen)
		T[a] = 'getal'
		T[b] = 'getal'
		t = 'ok'

	elseif exp[1] == 'var' then
		t = 'getal'

	-- zit hij erin?
	elseif exp[1] == 'som' then
		local ft = typen[exp[1]] -- functie type
		if isatoom(ft) then
			t = 'fout'
			f = 'kon geen som van '..leed(ft)..' nemen'
		else

			-- lijsten
			if ft[1] == '^' then
				-- index
				if ft[3] == 'int' then
					T[exp[2]] = 'int'
				else
					T[exp[2]] = {'..', 0, ft[3]}
				end
				t = ft[2]
			end

			-- functies
			if ft[1] == '->' then
				local van,naar = ft[2],ft[3]
				--T[exp[2]] = van
				--T[exp[3]] = naar
				--t = {'->', van, naar}
				t = naar
			end
		end

	-- tafel
	--elseif lijstlen(typen[exp[1]]) then
		

	-- functie
	elseif issimpel1(tfn) or issimpel2(tfn) or lijstlen(tfn) then
		if ta and ta[1] == '^' then
			a,b = b,a
			ta,tb = tb,ta
		end

		-- lengte
		local lengte = nil
		local l0

		-- subtype, fout
		local ti,fi = nil,{}
		for i=2,#exp do
			local a = exp[i]
			local ti1,f1 = exptypeer(a, typen)
			local l1 = lijstlen(ti1, typen)
			
			if ti1 == 'fout' then
				t,f = 'fout',f1
				break
			end

			fi[#fi+1] = f

			-- subtype
			local fi0
			local ti0 = ti and ti[2]
			local ti1 = l1 and ti1[2] or ti1
			ti,fi0 = verenig_of(ti0, ti1)
			if ti == 'fout' then
				t = 'fout'
				f = fi0
				break
			end

			lengte = verenig_en(l0,l1)

			if lengte == 'fout' then
				t = 'fout'
				f = 'lijstlengte ongelijkheid: '..leed(l0)..' != '..leed(l1)
				break
			end
			l0 = lengte
		end

		-- verenig lengten
		-- TODO

		-- bouwen
		ti = ti or 'iets'
		lengte = lengte or 1
		if lengte == 'fout' then
			t = 'fout'
			f = f
		elseif lengte == 1 then
			t = ti
		else
			t = {'^', ti, lengte}
		end
	end

	local t,f0 = verenig_en(t, typen[exp])
	typen[exp] = t
	if t == 'fout' then
		fouten[exp] = f or f0 or true
	end

	-- print de typen
	if print_typen then
		if t and not tonumber(exp) then
			print(leed(exp)..':\t'..color.yellow..leed(t)..color.white)
		end
		for exp,t in spairs(T) do
			if t and not tonumber(exp) and not typen[exp] then
				print('  '..leed(exp)..':\t'..color.yellow..leed(t)..color.white)
			end
		end
	end

	for exp,t0 in pairs(T) do
		local t1 = typen[exp]
		local f = F[exp]
		local t,f0 = verenig_en(t0,t1)
		if t and t ~= 'fout' then
			typen[exp] = t
		else
			fouten[exp] = fouten[exp] or f or f0 or true
		end
		--print('T', leed(t0), leed(t1), leed(t), f)
	end
	
	typen.aantalOnbekend = typen.aantalOnbekend + 1
	return t, f
end

local function print_onbekende_typen(exp, typen)
	if not typen[exp] then
		print(color.red .. 'kon type niet bepalen van ' .. unlisp(exp) .. color.white)
	end
	if isexp(exp) then
		for i,exp in ipairs(exp) do
			print_onbekende_typen(exp, typen)
		end
	end
end

-- invoer: print_typen
function typeer(feiten,typen)
	local typen = typen or {fouten = {}}
	local vroegerOnbekend = 999999

	while true do
		typen.aantalOnbekend = 0
	
		for i, feit in ipairs(feiten) do
			local type = exptypeer(feit, typen)
		end

		if typen.aantalOnbekend == vroegerOnbekend then
			break
		end
		vroegerOnbekend = typen.aantalOnbekend
	end

	-- fouten
	for t,f in spairs(typen.fouten) do
		if type(f) == 'string' then
			print(color.red..leed(t)..': '..f..color.white)
		end
	end
	for t,f in spairs(typen.fouten) do
		if type(f) == 'boolean' then
			print(color.yellow..'  '..leed(t)..color.white..': '..leed(typen[t]))
		end
	end
	print()

	if typen.aantalOnbekend > 0 then
		for k,v in spairs(typen) do
			if v == 'onbekend' then
				print('ONBEKEND:',leed(k))
			end
		end
	end

	for exp,type in pairs(typen) do
		if isatoom(exp) then
			--print(color.blue..leed(exp)..': '..leed(type)..color.white)
		end
	end

	-- alles na gaan
	if print_typen then
		for i,feit in ipairs(feiten) do
			print_onbekende_typen(feit, typen)
		end
	end

	local fouten = typen.fouten
	if not next(fouten) then fouten = nil end
	typen.fouten = nil
	return typen, fouten
end
