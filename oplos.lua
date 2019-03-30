require 'verenig'
require 'exp'
require 'isoleer'
require 'symbool'
require 'vhgraaf'
require 'bieb'
require 'rapport'

local print = function (...)
	local print0 = print
	if verboos then print(...) end
end

leed = combineer

function T(exp)
	local r = {}
	local function t(exp)
		if isatoom(exp) then
			r[#r+1] = exp.v
		else
			t(exp.fn)
			r[#r+1] = '('
			for i,v in ipairs(exp) do
				t(v)
				if exp[i+1] then
					r[#r+1] = ' '
				end
			end
			r[#r+1] = ')'
		end
	end
	t(exp)
	return table.concat(r)
end

local function pakpunten(exp,r)
	local r = r or {}
	r[#r+1] = exp
	if isexp(exp) then
		pakpunten(exp.fn,r)
		for i,v in ipairs(exp) do
			pakpunten(v,r)
		end
	end
	return r
end

function punten(exp)
	local r = pakpunten(exp)
	
	local i = 1
	return function ()
		if r[i] then
			local v = r[i]
			i = i + 1
			return v
		end
	end
end

-- it,fout,bekend,exp2naam
function oplos(exp,voor)
	if isatoom(exp) then return exp,nil,{},{} end
	if exp.fn.v == [[=]] or exp.fn.v == [[/\]] then
		local eqs
		if exp.fn.v == [[=]] then
			eqs = set(exp)
		else
			eqs = set(table.unpack(exp))
		end

		-- invoer ??
		local args = {}
		local function invoer(val)
			if isfn(val) then return false end
			val = val.v
			-- functie argumenten
			--if args[val] then return true end
			--if val.fn == '->' then args[val[1]] = true end
			if type(val) == 'string' and val:sub(1,1) == '_' then
				return true
			end

			if type(val) == 'table' then return false end
			return tonumber(val)
				or string.upper(val or '???')==val
				or val == 'standaardinvoer' -- kuch...
				or bieb[val] ~= nil -- KUCH KUCH
		end

		-- herschrijf (b ⇒ (a = c)) → (a |= (b ⇒ c))
		for eq in pairs(eqs) do
			local a = (eq.fn.v == '=>') 
			local b = isexp(eq[2]) 
			local c = b and (eq[2].fn.v == '=')
			if eq.fn.v == '=>' and isexp(eq[2]) and eq[2].fn.v == '=' then
				eq.fn.v = '|='
				eq[1],eq[2] = eq[2][1], {fn=X'=>', eq[1], eq[2][2]}
			end
		end

		-- verzamel |=
		local map = {} -- k → [v]
		local oud = {}
		for eq in pairs(eqs) do
			-- a |= b
			if eq.fn.v == '|=' then
				local a,b = eq[1],eq[2]
				map[a.v] = map[a.v] or {}
				local v = map[a.v]
				v[#v+1] = b
				oud[eq] = true
			end
		end
		for eq in pairs(oud) do
			eqs[eq] = false
		end
		for naam,alts in pairs(map) do
			alts.fn = X'|'
			if #alts == 1 then
				alts = alts[1]
			end
			local eq = {fn=X'=', X(naam), alts}
			eqs[eq] = true
		end

		-- functies
		local aantal = 1
		local nieuw = {}
		local afval = {}
		for eq in pairs(eqs) do
			for lam in punten(eq) do
				if isexp(lam) and lam.fn.v == '->' then
					local inn,uit = lam[1],lam[2]
					local params
					if isexp(inn) and inn.fn.v == ',' and false then
						params = inn
					else
						params = {inn}
					end

					-- complexe parameters
					for i,param in ipairs(params) do
						if not isatoom(param) or true then
							local naam = X('_'..varnaam(aantal))
							params[i] = naam
							local paramhulp = {fn=X'=', naam, param}
							nieuw[paramhulp] = true -- HIER!

							-- pas vergelijking aan
							lam[1] = naam
							--for i,v in ipairs(lam) do lam[i] = nil end
							--for k,v in pairs(uit) do lam[k] = v end

							aantal = aantal + 1
						end
					end
				end
			end
		end
		for eq in pairs(nieuw) do eqs[eq] = true end

		-- los vergelijkingen op
		-- -> multimap = lijst(:=(A,B))
		local subst = {}
		for eq in pairs(eqs) do
			if eq.fn.v == [[=]] then
				for naam in pairs(var(eq,invoer)) do
					--if naam ~= eq[1] and naam ~= eq[2] then
						--if verboos then print('Probeer', naam, toexp(eq)) end
						local waarde = isoleer(eq,naam)
						if waarde then
							local eq = {fn=X':=', naam, waarde}
							subst[eq] = true
							if verboos then print('ISOLEER', exp2string(eq)) end
						end
					--end
				end
			end
		end

		-- maak graaf
		local kennisgraaf = vhgraaf()
		local pijl2subst = {}
		for subst in pairs(subst) do
			local _,naam,waarde = ':=',subst[1],subst[2]
			local bron0 = var(waarde,invoer)
			local bron = {}
			for k in pairs(bron0) do -- alleen naam is nodig
				--assert(type(k.v) == 'string', see(k.v))
				bron[k.v] = true
			end
			local pijl = kennisgraaf:link(bron, naam.v)
			pijl2subst[pijl] = subst
		end
		print()
		print('# Kennisgraaf')
		print(kennisgraaf:tekst())
		print()

		local stroom,fout,bekend = kennisgraaf:sorteer(invoer,voor)
		local vt = {
			code = "ABC",
			kennisgraaf = kennisgraaf,
			infostroom = stroom or kennisgraaf,
		}
		if verboos then file('rapport.html', rapport(vt)) end
		if not stroom then
			file('fout.html', rapport(vt))
			return false, 'kon kennisgraaf niet sorteren:\n'..kennisgraaf:tekst(), bekend, {}
		end
		print()
		print('Stroom verkregen')
		print(stroom:tekst())
		print()
		local substs = stroom:topologisch()
		if not substs then
			return false, 'kon niet topologisch sorteren', bekend, {}
		end
		-- lijst(subst)

		-- op te lossen waarde, staat die niet altijd laatste (;
		--TODOlocal val = voor
		local val = X'uit'
		local exp2naam = {}

		print()
		print('Begin substitutie', exp2string(val))
		local exp2naam = {}
		for i=#substs,1,-1 do
			local sub = pijl2subst[substs[i]]
			local naam,exp = sub[1],sub[2]
			local val0 = val
			val = substitueer(val0, naam, exp)
			--exp2naam[val0] = naam
			--print('SUBST', exp2string(val0), exp2string(naam), exp2string(exp), exp2string(val))
			print('SUBST', naam.v)

			print('ONTKEVER', exp2string(exp))

			exp2naam[naam.v] = exp
			local n2e = {}
			for k,v in pairs(exp2naam) do
				n2e[k] = substitueer(v, naam, exp)
				print('N2E', exp2string(n2e[k]))
			end
			exp2naam = n2e
		end

		print('Klaar', exp2string(val))
		print()

		return val,nil,bekend,exp2naam

		-- functie ontleding
		--[=[
		for eq in pairs(eqs) do
			if eq.fn == [[=]] then
				local fx,val = eq[1],eq[2]
				-- (...) = f
				if isexp(fx) then
					-- (f x) = g
					if not isinvoer(fx.fn) and not isinvoer(fx[1]) and bevat(val, fx[1]) then
						eq[1] = fx.fn
						eq[2] = toexp {fn='->', fx[1], val}
					end
				end
			end
		end
		]=]

		--return verenig(eqs, isinvoer)

	end

	return exp,nil,bekend,exp2naam
end

if test then
	require 'util'
	require 'ontleed'

	assert(oplos(ontleed('a = 2', 'a')) == '2')

	-- b = 2 + 2
	local v = oplos(ontleed('a = 2\na + 2 = b'))
	assert(v)
	assert(tostring(v.b) == '+(2 2)',
		'v.b = '..tostring(v.b)..' ≠ +(2 2)')

	local v = oplos(ontleed('f(a) = f(b)\na = 2'))
	assert(v)
	assert(tostring(v.b) == '2',
		'v.b = '..tostring(v.b)..' ≠ 2')

	local v = oplos(toexp(ontleed('f(a + 1) = f(b + 1)\na = 2')))
	assert(v)
	assert(tostring(v.b) == '2',
		'v.b = '..tostring(v.b)..' ≠ 2')

	local v = oplos(toexp(ontleed('f = g⁻¹ ∧ g = ★ - 3')))
	print(toexp(ontleed('f = g⁻¹ ∧ g = ★ - 3')))
	assert(v)
	assert(tostring(v.f) == 'inverteer(-(_ 3))', tostring(v.f))

	local s = [[
f = ★/2 ∘ sin
a = f⁻¹(2)
	]]
	local c = oplos(toexp(ontleed(s)))

	for i=1,10 do
		local s = [[
standaarduitvoer = "a = " || tekst(a) || [10]
a = f(3)
f = sin ∘ cos
		]]
		local m = oplos(toexp(ontleed(s)))
		assert(m.standaarduitvoer)
	end

end
