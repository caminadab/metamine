require 'symbool'
require 'func'
require 'util'

local prios = {
	['^'] = 3, ['_'] = 3,
	['*'] = 2, ['/'] = 2,
	['+'] = 1, ['-'] = 1,
	['='] = 0,
}

local function issimpel1(t)
	return isexp(t) and t[1] == '->' and isatoom(t[2]) and isatoom(t[3])
end
assert(issimpel1{'->', 'getal', 'getal'})

local function issimpel2(t)
	if not isexp(t) then return false end
	local argn = t[2]
	local bi = isexp(argn) and #argn == 3 and isatoom(argn[2]) and isatoom(argn[3])
	return isexp(t) and t[1] == '->' and bi
end

local dichtbij = {['^']=true,['_']=true,['.']=true}
function leedwerk(exp, t)
	local prio = 0
	if isatoom(exp) then
		t[#t+1] = exp
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
		leedwerk(exp[2], t)
	elseif #exp == 3 then
		leedwerk(exp[2], t)
		if not dichtbij[exp[1]] then t[#t+1] = ' ' end
		leedwerk(exp[1], t)
		if not dichtbij[exp[1]] then t[#t+1] = ' ' end
		leedwerk(exp[3], t)
	end
	return t
end

function leed(exp)
	local exp = exp or 'niets'
	local t = leedwerk(exp, {})
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

	-- echte logica
	if tonumber(tb) then ta,tb = tb,ta end

	if tonumber(ta) and tonumber(tb) and ta ~= tb then
		return 'getal'
	end
	if tonumber(ta) and (tb == 'getal' or tb == 'int') then
		return tb
	end

	return 'fout', leed(ta)..' != '..leed(tb)
end
assert(verenig_of('2', 'int') == 'int')

-- nil = onbekend, fout = fout
local function verenig_en(ta, tb)
	if ta and not tb then return ta end
	if tb and not ta then return tb end
	if not ta and not tb then return nil end 
	if ta == 'fout' or tb == 'fout' then return 'fout' end
	if unlisp(ta) == unlisp(tb) then
		return ta
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

local vastetypen = {
	nu = 'moment',
	tau = 'getal',
	['toets-rechts'] = 	'getal',
	['toets-links'] =		'getal',
	['toets-omhoog'] = 	'getal',
	['toets-omlaag'] = 	'getal',
	['toets-spatie'] = 	'getal',
}

-- lengte of een lijst type
function lijstlen(t, typen)
	if isatoom(t) then return nil end
	if t[1] == '^' then return tostring(t[3]) end --TEMP tostring
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

	-- vergelijking
	elseif exp[1] == '=' then
		local a,b = exp[2], exp[3]
		local ta,fa = exptypeer(a, typen)
		local tb,fb = exptypeer(b, typen)
		local tab,fab = verenig_en(ta,tb)
		T[a] = tab
		T[b] = tab
		if tab and tab~='fout' then
			t = 'ok'
		else
			t = 'fout'
			--print(fa,fb,fab)
			f = nil--fa or fb or fab or 'uhh'--leed(ta)..' != '..leed(tb)
		end

	-- lijsten
	elseif exp[1] == '[]' then
		local ti = nil
		for i=2,#exp do
			local a = exp[i]
			local ta = exptypeer(a, typen)
			ti = verenig_of(ti, ta)
		end
		if not ti then
			t = 'fout'
			f = 'kon type van lijst niet bepalen'
		else
			t = {'^', ti, #exp-1}
		end

	-- functie
	elseif issimpel1(typen[exp[1]]) or issimpel2(typen[exp[1]]) then
			local fn,a,b,c = table.unpack(exp) --exp[1], exp[2], exp[3], exp[4]

			-- lengte
			local lengte = nil

			-- subtypen, fouten, lengten
			local ti,fi = nil,{}
			for i=2,#exp do
				local a = exp[i]
				local ti1,f1 = exptypeer(a, typen)
				local l1 = lijstlen(a)
				
				if t1 == 'fout' then
					t,f = 'fout',f1
					break
				end

				fi[#fi+1] = f

				-- subtype
				local t0 = ti
				ti = verenig_of(ti0, ti1)
				if ti == 'fout' then
					t = 'fout'
					f = '???'
					break
				end

				lengte = verenig_en(l0,l1)
				
				if lengte == 'fout' then
					t = 'fout'
					f = 'lijstlengte ongelijkheid: '..leed(l0)..' != '..leed(l1)
					break
				end
			end

			-- verenig lengten
			-- TODO

			-- bouwen
			ti = ti or 'iets'
			lengte = lengte or 1
			if lengte == 1 then
				t = ti
			else
				t = {'^', ti, lengte}
			end

			--[[
			local ta,tb = exptypeer(a, typen), exptypeer(b, typen)
			
			-- elementswijs
			local la, lb = lijstlen(ta), lijstlen(tb)
			if la and lb then
				if la == lb then
					t = {'^', verenig_of(ta[2], tb[2]), ta[3]}
				else
					t = 'fout'
					f = 'lijstlengte ongelijkheid: '..leed(la)..' != '..leed(lb)
				end
			end

			-- automagie
			if lb and not la then
				la,lb = lb,la
				ta,tb = tb,ta
			end

			-- [0,1] + 0
			-- ta: getal^2, tb: getal
			if la and not lb then
				t = {'^', verenig_of(ta[2], tb), ta[3]}
			end

			if not la and not lb then
				t = 'fout'
				f = 'lijstlengte onbekend'
			end
			]]

		-- zit hij erin?
		elseif typen[exp[1]] then
			local ft = typen[exp[1]] -- functie type
			if isatoom(ft) then
				typen[exp] = 'fout'
				return typen[exp]
			else

				-- lijsten
				if ft[1] == '^' then
					-- index
					if ft[3] == 'int' then
						typen[exp[2]] = 'int'
					else
						typen[exp[2]] = {'..', 0, ft[3]}
					end
					t = ft[2]
				end

				-- functies
				if ft[1] == '->' then
					local van,naar = ft[2],ft[3]
					typen[exp[2]] = van
					t = naar
				end
			end
		end

	local t,f0 = verenig_en(t, typen[exp])
	typen[exp] = t
	if t == 'fout' then
		fouten[exp] = f or f0 or true
	end

	for exp,t0 in pairs(T) do
		local t1 = typen[exp]
		local t,f0 = verenig_en(t0,t1)
		if t and t ~= 'fout' then
			typen[exp] = t
		else
			fouten[exp] = fouten[exp] or f or f0 or true
		end
		--print('T', leed(t0), leed(t1), leed(t), f)
	end
	
	if print_typen then
		print(leed(exp)..': '..leed(t))
		for exp,t in pairs(T) do
			print('  '..leed(exp)..': '..leed(t))
		end
	end

	typen.aantalOnbekend = typen.aantalOnbekend + 1
	return t, f
end

-- invoer: print_typen
function typeer(feiten,typen)
	local typen = typen or {aantalOnbekend = 0,fouten = {}}
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
			print(color.orange..'  '..leed(t)..color.white)
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

	local fouten = typen.fouten
	if not next(fouten) then fouten = nil end
	typen.fouten = nil
	return typen, fouten
end
