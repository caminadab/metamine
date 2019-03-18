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

local function pakpunten(exp,r)
	local r = r or {}
	r[#r+1] = exp
	if isexp(exp) then
		for k,v in pairs(exp) do
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

function oplos(exp,voor)
	if exp.fn == [[=]] or exp.fn == [[/\]] then
		local eqs
		if exp.fn == [[=]] then
			eqs = set(exp)
		else
			eqs = set(table.unpack(exp))
		end

		-- invoer ??
		local args = {}
		local function invoer(val)
			-- functie argumenten
			--if args[val] then return true end
			--if val.fn == '->' then args[val[1]] = true end
			if type(val) == 'string' and val:sub(1,1) == '_' then
				return true
			end

			if type(val) == 'table' then return false end
			return tonumber(val)
				or string.upper(val)==val
				or val == 'standaardinvoer' -- kuch...
				or bieb[val] ~= nil -- KUCH KUCH
		end

		-- herschrijf (b ⇒ (a = c)) → (a |= (b ⇒ c))
		for eq in pairs(eqs) do
			local a = (eq.fn == '=>') 
			local b = isexp(eq[2]) 
			print('AAAA', toexp(eq))
			local c = (eq[2].fn == '=')
			if eq.fn == '=>' and isexp(eq[2]) and eq[2].fn == '=' then
				eq.fn = '|='
				eq[1],eq[2] = eq[2][1], {fn='=>', eq[1], eq[2][2]}
			end
		end

		-- verzamel |=
		local map = {} -- k → [v]
		local oud = {}
		for eq in pairs(eqs) do
			-- a |= b
			if eq.fn == '|=' then
				local a,b = eq[1],eq[2]
				map[a] = map[a] or {}
				local v = map[a]
				v[#v+1] = b
				oud[eq] = true
			end
		end
		for eq in pairs(oud) do
			eqs[eq] = false
		end
		for k,v in pairs(map) do
			v.fn = '|'
			local eq = {fn='=', k, v}
			eqs[eq] = true
		end

		-- functies
		local aantal = 1
		local nieuw = {}
		local afval = {}
		for eq in pairs(eqs) do
			for lam in punten(eq) do
				if isexp(lam) and lam.fn == '->' then
					local inn,uit = lam[1],lam[2]
					local params
					if isexp(inn) and inn.fn == ',' then
						params = inn
					else
						params = {inn}
					end

					-- complexe parameters
					for i,param in ipairs(params) do
						if not isatoom(param) or true then
							local naam = '_'..varnaam(aantal)
							params[i] = naam
							local paramhulp = {fn='=', naam, param}
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
			if eq.fn == [[=]] then
				for naam in pairs(var(eq,invoer)) do
					--if naam ~= eq[1] and naam ~= eq[2] then
						--if verboos then print('Probeer', naam, toexp(eq)) end
						local waarde = isoleer0(eq,naam)
						if waarde then
							local eq = {fn=':=', naam, waarde}
							subst[eq] = true
							if verboos then print('ISOLEER', toexp(eq)) end
						end
					--end
				end
			end
		end

		-- maak graaf
		local kennisgraaf = vhgraaf()
		local pijl2subst = {}
		for subst in pairs(subst) do
			local naam,waarde = subst[1],subst[2]
			local bron
			if false and isexp(waarde) and waarde.fn == '->' then
				bron = {}
			else
				bron = var(waarde,invoer)
			end
			local pijl = kennisgraaf:link(bron, naam)
			pijl2subst[pijl] = subst
		end
		print('Heb nu\n', kennisgraaf:tekst())

		local stroom = kennisgraaf:sorteer(invoer,voor)
		local vt = {
			code = "ABC",
			kennisgraaf = kennisgraaf,
			infostroom = stroom or kennisgraaf,
		}
		if verboos then file('rapport.html', rapport(vt)) end
		if not stroom then
			if verboos then file('fout.html', rapport(vt)) end
			return false, 'kon kennisgraaf niet sorteren:\n'..kennisgraaf:tekst()
		end
		local substs = stroom:topologisch()
		if not substs then
			return false, 'kon niet topologisch sorteren'
		end
		-- lijst(subst)

		-- op te lossen waarde, staat die niet altijd laatste (;
		local val = voor
		local exp2naam = {}

		print()
		print('Begin substitutie', val)
		for i=#substs,1,-1 do
			local sub = pijl2subst[substs[i]]
			local naam,exp = sub[1],sub[2]
			local val0 = val
			val = substitueer(val0, naam, exp)
			exp2naam[val0] = naam
			print('Stapje', toexp(val0), toexp(naam), toexp(exp), toexp(val))
		end

		print('Klaar', toexp(val))
		print()

		return val,nil,exp2naam

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

	return exp,nil,exp2naam
end

if test then
	require 'util'
	require 'ontleed'

	assert(oplos(ontleed0('a = 2', 'a')) == '2')

	-- b = 2 + 2
	local v = oplos(ontleed0('a = 2\na + 2 = b'))
	assert(v)
	assert(tostring(v.b) == '+(2 2)',
		'v.b = '..tostring(v.b)..' ≠ +(2 2)')

	local v = oplos(ontleed0('f(a) = f(b)\na = 2'))
	assert(v)
	assert(tostring(v.b) == '2',
		'v.b = '..tostring(v.b)..' ≠ 2')

	local v = oplos(toexp(ontleed0('f(a + 1) = f(b + 1)\na = 2')))
	assert(v)
	assert(tostring(v.b) == '2',
		'v.b = '..tostring(v.b)..' ≠ 2')

	local v = oplos(toexp(ontleed0('f = g⁻¹ ∧ g = ★ - 3')))
	print(toexp(ontleed0('f = g⁻¹ ∧ g = ★ - 3')))
	assert(v)
	assert(tostring(v.f) == 'inverteer(-(_ 3))', tostring(v.f))

	local s = [[
f = ★/2 ∘ sin
a = f⁻¹(2)
	]]
	local c = oplos(toexp(ontleed0(s)))

	for i=1,10 do
		local s = [[
standaarduitvoer = "a = " || tekst(a) || [10]
a = f(3)
f = sin ∘ cos
		]]
		local m = oplos(toexp(ontleed0(s)))
		assert(m.standaarduitvoer)
	end

end
