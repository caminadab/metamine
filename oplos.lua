require 'exp'
require 'combineer'
require 'isoleer'
require 'symbool'
require 'vhgraaf'
require 'bieb'
require 'rapport'

leed = combineer

local bieb = bieb()

function T(exp)
	local r = {}
	local function t(exp)
		if isatoom(exp) then
			r[#r+1] = exp.v
		else
			t(exp.f)
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
		pakpunten(exp.f,r)
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

		-- fix dubbele args: f(,(2 3))
		-- herschrijf (a := b) naar (a |= (start ⇒ b) | a')
		-- herschrijf (a(b) = c) naar (a ∐= b ↦ c)
		-- herschrijf (c = a(b)) naar (a ∐= b ↦ c)
		-- herschrijf (a ||= b) naar (a |= a' || b)
		-- herschrijf (a < b) → (a: (b..∞) ∧ b: (-∞ .. a))
		-- vind atomen

		-- herschrijf
		--   c ⇒ (a = b)
		-- naar
		--   a |= (c ⇒ b)
		--   b |= (c ⇒ a)
		-- 
		-- en
		--   ⇒(c, d, (x = y))
		-- naar
		--   x |= (¬d ⇒ y)
		--   y |= (¬d ⇒ x)
		-- herschrijf  f(a) = a + 1
		-- naar        f ∐= a → a + 1
		-- verzamel |=
		-- verzamel ∈ en ∋
		-- herschrijf
		--   a = f(a')
		-- naar
		--   a = (herhaal (a' → a))(niets)
		-- functieargumenten

-- oplos: exp → waarde,fouten
function oplos(exp,voor)
	local maakvar = maakvars()
	local fouten = {}
	if isatoom(exp) then return X'ZWARE FOUT',fouten end -- KAN NIET
	if exp.f.v == [[=]] or exp.f.v == [[⋀]] then
		local eqs
		if exp.f.v == [[=]] then
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
			--if val.f == '→' then args[val[1]] = true end
			if type(val) == 'string' and val:sub(1,1) == '_' then -- TODO
				return true
			end

			if type(val) == 'table' then return false end
			return (tonumber(val) and true)
				or string.upper(val or '???')==val
				or val == '_arg'
				or val == '_fn'
				or bieb[val] ~= nil -- KUCH KUCH
		end

		local nieuw, oud = {}, {}

		-- a' is niet op momenten gedefinieerd maar alleen vlak ervoor

		-- herschrijf (a := b) naar (a := (l → (l=0 ⇒ b)))
		-- ** (a := b) naar (a := (start, b))
		for eq in pairs(eqs) do
			if eq.f and eq.f.v == ':=' then
				local a, b = eq.a[1], eq.a[2]

				-- local neq = 
				--local neq = X(sym.ass, a, X(sym.map, maakvar(), X(sym.dan, X(sym.is, 'looptijd', '0'), b)))
				local neq = X('|:=', a, X('⇒', 'init', b, 'niets'))
				--print(e2s(neq))
				oud[eq] = true
				nieuw[neq] = true
			end
		end

		-- herschrijf (a(b) = c) naar (a ∐= b ↦ c)
		for eq in pairs(eqs) do
			--if isfn(eq) and isfn(eq[1]) --[[and isatoom(eq[1].f)]] and isatoom(eq[1][1]) and #eq[1] == 1 then
			if isfn(eq) and isfn(eq.a[1]) and false then --TODO and #eq[1] == 1 then
				local a, b, c  = eq.a[1].f, eq.a[1].a[1], eq.a[2]
				local neq = X(sym.cois, a, X(sym.map, b, c))
				local meq = X(sym.cois, a, X(sym.map, b, c))
				oud[eq] = true
				nieuw[neq] = true
				--error(exp2string(neq))
			end

		-- herschrijf (c = a(b)) naar (a ∐= b ↦ c)
			if false and isfn(eq) and eq.a[2] and isfn(eq.a[2]) --[[and isatoom(eq.a[2].f)]] and isatoom(eq.a.a[2].a[1]) and #eq.a[2] == 1 then
				local a, b, c  = eq.a[2].f, eq.a[2].a[1], eq.a[1]
				local neq = X(sym.cois, a, X(sym.map, b, c))
				--oud[eq] = true
				nieuw[neq] = true
			end
		end

		-- herschrijf (a ||= b) naar (a |= a' || b)
		for eq in pairs(eqs) do
			for exp in boompairs(eq) do
				if exp.f and exp.f.v == "||=" then --== sym.catass then
					local a, b = exp.a[1], exp.a[2]
					exp.f, exp.a[1], exp.a[2] = sym.altis, a, X(sym.cat, X(sym.oud, a), b)
				end
			end
		end

		-- herschrijf (a < b) → (a: (b..∞) ∧ b: (-∞ .. a))
		for eq in pairs(eqs) do
			if isfn(eq) and eq.f.v == '>' then
				eq.f.v,fn,eq.a[2],eq.a[1] = '<',eq.a[1],eq.a[2]
			end
			if isfn(eq) and eq.f.v == '<' then
				local fa = X(X':', eq.a[1], X(X'..', eq.a[2], X'oneindig'))
				local fb = X(X':', eq.a[2], X(X'..', X(X'-', X'oneindig'), eq.a[1]))
				nieuw[fa] = true
				nieuw[fb] = true
				oud[eq] = true
			end
		end

		local i = 0
		-- vind atomen
		for eq in pairs(eqs) do
			for exp in boompairs(eq) do
				if isfn(exp) and exp.f.v == '.' then
					exp.f, exp.a.a[2] = X'=', {f=X'atoom', X(tostring(i)), naam=exp.a[1].v }
					i = i + 1
				end
			end
		end

		-- pak blokken uit
		for eq in pairs(eqs) do
			if fn(eq) == '⇒' then
				if fn(eq.a[2]) == '⋀' then
					for i,sub in ipairs(eq.a[2]) do
						local neq = X('⇒', eq.a[1], sub)--X'niets')
						if fn(sub) == '|:=' then
							--eq = X('⇒', X('wanneer', eq.a[1]), 
							sub = X('[]', sub.a[1], sub.a[2])
						end
						nieuw[neq] = true
						oud[eq] = true

						--print('BLOK', e2s(eq))
					end
				end
				if eq[3] and fn(eq[3]) == '⋀' then
					for i,sub in ipairs(eq[3]) do
						local eq = X('⇒', X('¬', eq.a[1]), sub)--X'niets')
						nieuw[eq] = true
						--print('BLOK', e2s(eq))
					end
				end
			end
		end

		eqs = unie(eqs, nieuw)

		-- herschrijf
		--   c ⇒ (a = b)
		-- naar
		--   a |= (c ⇒ b)
		--   b |= (c ⇒ a)
		-- 
		-- en
		--   ⇒(c, d, (x = y))
		-- naar
		--   x |= (¬d ⇒ y)
		--   y |= (¬d ⇒ x)
		for eq in pairs(eqs) do
			if fn(eq) == '⇒' and (fn(eq.a[2]) == '=' or fn(eq.a[2]) == '|=' or fn(eq.a[2]) == ':=') then
				--error('OK')
				
				eq.f.v = '|='
				if fn(eq.a[2]) == ':=' then
					eq.f.v = '|:='
				end
				local alt = eq.f
				local c = eq.a[1]
				local a = eq.a[2].a[1]
				local b = eq.a[2].a[2]

				-- twee nieuwe
				local ae = eq[3] and eq[3].a[1] or X'niets'
				local be = eq[3] and eq[3].a[2] or X'niets'
				--assert(ae and be)
				local eqa = X{f=alt, a, {f=sym.dan, c, b, be}}
				local eqb = X{f=alt, b, {f=sym.dan, c, a, ae}}
				nieuw[eqa] = true
				nieuw[eqb] = true

				if false and eq[3] and (fn(eq[3]) == '=' or fn(eq[3]) == '|=') then
					local e = {f=sym.niet, c}
					local ae = eq[3].a[1]
					local be = eq[3].a[2]
					local eqa = {f=alt, ae, {f=sym.dan, e, be}}
					local eqb = {f=alt, be, {f=sym.dan, e, ae}}
					nieuw[eqa] = true
					nieuw[eqb] = true
				end
			end
		end
		eqs = complement(eqs, oud)
		eqs = unie(eqs, nieuw)
		nieuw = {}
		oud = {}
		
		-- TODO f(x) = x + 2  →  f = x → x + 2

		eqs = complement(eqs, oud)
		eqs = unie(eqs, nieuw)

		-- verzamel |=
		local map = {} -- k → [v]
		local oud = {}
		for eq in pairs(eqs) do
			-- a |= b
			if isfn(eq) and eq.f.v == '|=' then
				local a,b = eq.a[1],eq.a[2]
				map[a.v or a] = map[a.v or a] or {}
				local v = map[a.v or a]
				v[#v+1] = b
				oud[eq] = true
			end
		end
		for eq in pairs(oud) do
			eqs[eq] = false
		end
		for naam,alts in pairs(map) do
			alts.f = X'|'
			if #alts == 1 then
				alts = alts[1]
			end
			local eq = {f=X'=', X(naam), alts}
			eqs[eq] = true
		end

		-- verzamel |:=
		local schaduw = {}
		local map = {} -- k → [v]
		local oud = {}
		for eq in pairs(eqs) do
			-- a |= b
			if isfn(eq) and eq.f.v == '|:=' then
				print(e2s(eq))
				local a,b = eq.a[1],eq.a[2]
				map[a.v or a] = map[a.v or a] or {}
				local v = map[a.v or a]
				v[#v+1] = b
				oud[eq] = true
			end
		end
		for eq in pairs(oud) do
			eqs[eq] = false
		end
		local maakindex = maakindices()
		for naam,alts in pairs(map) do
			alts.f = X'{}'
			--if #alts == 1 then
			--	alts = alts[1]
			--end
			local index = maakindex()
			schaduw[naam] = index
			print('SCHADUW', naam)
			local eq = {f=X'=', X(naam), X('var', index, alts)}
			eqs[eq] = true
		end
		
		-- verzamel ∐=
		local map = {} -- k → [v]
		local oud = {}
		for eq in pairs(eqs) do
			-- a ∐= b
			if isfn(eq) and eq.f.v == 'co=' then
				local a,b = eq.a[1],eq.a[2]
				map[a.v or a] = map[a.v or a] or {}
				local v = map[a.v or a]
				v[#v+1] = b
				oud[eq] = true
			end
		end
		for eq in pairs(oud) do
			eqs[eq] = nil
		end
		for naam,alts in pairs(map) do
			alts.f = X'co'
			if #alts == 1 then
				alts = alts.a[1]
			end
			local eq = {f=X'=', X(naam), alts}
			eqs[eq] = true
		end

		-- verzamel ∈ en ∋
		local map = {} -- k → [v]
		local oud = {}
		for eq in pairs(eqs) do
			-- a ∐= b
			if isfn(eq) and (eq.f.v == 'bevat' or eq.f.v == 'zitin') then
				if eq.f.v == 'zitin' then
					eq.f,eq.a[1],eq.a[2] = X'bevat',eq.a[2],eq.a[1]
				end
				local a,b = eq.a[1],eq.a[2]
				map[a.v or a] = map[a.v or a] or {}
				local v = map[a.v or a]
				v[#v+1] = b
				oud[eq] = true
			end
		end
		for eq in pairs(oud) do
			eqs[eq] = nil
		end
		for naam,alts in pairs(map) do
			alts.f = X'UNIE'
			local eq = {f=X'=', X(naam), alts}
			eqs[eq] = true
		end

		--[[
		S = 0
		-- herschrijf
		--   a = f(a')
		-- naar
		--   a = (herhaal (a' → a))(niets)
		local nieuw = {}
		local oud = {}
		for eq in pairs(eqs) do
			if isfn(eq) and isatoom(eq.a[1]) and eq.f.v == '=' then
				local a,b = eq.a[1],eq.a[2]
				for node in boompairs(b) do
					if isfn(node) and node.f.v == "'" and node[1].v == a.v then
						local oude = X(node[1].v .. '_oud')
						b = substitueerzuinig(b, node, oude, maakvar)
						node.f = nil
						node.v = a.v
						eqn = X('=', a, X(X('herhaal', X('→', oude, b)), 'niets'))
						oud[eq] = true
						nieuw[eqn] = true
					end
				end
			end
		end
		]]


		-- herschrijf
		--   a'
		-- naar
		--   var(0)
		local nieuw = {}
		local oud = {}
		local maakindex = maakindices()
		for eq in pairs(eqs) do
			for exp in boompairs(eq) do
				if fn(exp) == "'" and exp.a.v then
					local naam = exp.a.v
					--schaduw[naam] = maakindex() 
					-- a' ↦ var(0)
					exp.f = X('prevvar')
					assert(schaduw[naam], 'onbekende variabele: '..naam)
					exp.a = X(schaduw[naam])
				end
			end
		end

		eqs = unie(eqs, nieuw)
		eqs = complement(eqs, oud)

		-- uit = (start ⇒ "ok") | (looptijd = 1 ⇒ uit' || "ok")

		-- functies
		local maakindex = maakindices()
		local nieuw = {}
		local afval = {}

		-- herschrijf a→a+1 naar _fn(0 +(_arg(0) 1))
		for eq in pairs(eqs) do
			for lam in punten(eq) do

				-- 
				if fn(lam) == '→' then
					local inn,uit = lam.a[1],lam.a[2]

					-- pas vergelijking aan
					for i in pairs(lam) do lam[i] = nil end
					lam.f = X'_fn'
					lam.a = uit

					-- complexe parameters
					local paramhulp = {f=X'=', naam, inn}
					nieuw[paramhulp] = true -- HIER!

				end
			end
		end
		for eq in pairs(nieuw) do eqs[eq] = true end

		-- los vergelijkingen op
		-- → multimap = lijst(:=(A,B))
		local subst = {}
		for eq in pairs(eqs) do
			if isfn(eq) and eq.f.v == [[=]] then
				for naam in pairs(var(eq,invoer)) do
					--if naam ~= eq[1] and naam ~= eq.a[2] then
					if bieb[naam] == nil then
						--if verboos then print('Probeer', naam, toexp(eq)) end
						local waarde = isoleer(eq,naam)
						if waarde then
							local eq = {f=X':=', naam, waarde}
							subst[eq] = true
							--if verbozeOplos then print('SUBST', exp2string(eq)) end
						end
					end
				end
			end
		end

		if verbozeKennis then
			print('=== VOORGEKAUWD ===')
			for eq in pairs(eqs) do
				print(combineer(eq))
			end
			print()
		end

		-- maak graaf
		local kennisgraaf = vhgraaf()
		local pijl2subst = {}
		local bron2def = {}
		for subst in pairs(subst) do
			local naam,waarde = subst[1],subst.a[2]
			local bron0 = var(waarde,invoer)
			local bron = {}
			for k in pairs(bron0) do -- alleen naam is nodig
				--assert(type(k.v) == 'string', see(k.v))
				bron[k.v] = true
				bron2def[k.v] = k
			end
			local pijl = kennisgraaf:link(bron, naam.v)
			pijl2subst[pijl] = subst
		end

		-- ULTIEME KENNISGRAAF
		if verbozeKennisgraaf then
			print(kennisgraaf:tekst())
		end

		local stroom,halfvan,halfnaar = kennisgraaf:sorteer(invoer,voor)

		-- RAPPORTJE SCHRIJVEN
		if verbozeRapport then
			local rap = rapport {kennisgraaf = kennisgraaf, infostroom = stroom}
			file('rapport.html', rap)
			print('rapport weggeschreven naar "rapport.html"')
		end

		local vt = {
			code = "ABC",
			kennisgraaf = kennisgraaf,
			infostroom = stroom or kennisgraaf,
		}
		if verboos then file('rapport.html', rapport(vt)) end
		if not stroom then
			--file('fout.html', rapport(vt))
			--return false, 'kon kennisgraaf niet sorteren:\n'..kennisgraaf:tekst(), bekend, {}, halvestroom

			local fouten = {}
			if false then
				print('HALV VAN')
				print(halfvan:tekst())
				print('HALV NAAR')
				print(halfnaar:tekst())
			end
			for punt in pairs(halfnaar.begin) do
				if not halfvan.punten[punt] then
					local def = bron2def[punt]
					local fout = oplosfout(def.loc, '{code} is ongedefinieerd', punt)
					fouten[#fouten+1] = fout
				end
			end
			return false, fouten, {}
		end
		local substs = stroom:topologisch()
		if not substs then
			-- dit is een zware fout...
			return false, {oplosfout(nergens, 'zware fout')}
		end
		-- lijst(subst)

		-- op te lossen waarde, staat die niet altijd laatste (;
		--TODOlocal val = voor
		local val = X(voor)--X'uit'
		local exp2naam = {}
		-- sets van exps, op naam
		local naam2exp = {}
		
		-- O(diepte · sz)
		for i=#substs,1,-1 do
			local sub = pijl2subst[substs[i]]
			local naam,exp = sub[1],sub.a[2]
			local val0 = val
			local n
			naam2exp[naam] = naam2exp[naam] or {}
			--naam2exp[naam][exp] = true
			val, n = substitueerzuinig(val0, naam, exp, maakvar)
			val.loc = assert(exp.loc or nergens)
			--exp2naam[val0] = naam
			--print('SUBST', exp2string(val0), exp2string(naam), exp2string(exp), exp2string(val))
			if true or verboos then
				--print('SUBST', naam.v, n)
			end

			exp2naam[naam.v] = exp
			local n2e = {}
			for k,v in pairs(exp2naam) do
				local n
				n2e[k],n = substitueerzuinig(v, naam, exp, maakvar)
				--print('SUBST', combineer(exp), n..'x')
			end
			exp2naam = n2e
		end
		--print('aantal subcalls = ', S)

		--[[
		-- nog ff sneaken
		-- functies toepassen
		--error(exp2string(val))
		for exp in boompairs(val) do
			if isfn(exp) and fn(exp.f) == '_fn' then
				local waarde = exp.f[1]
				for i=2,#exp.f do
					local narg = exp.f[i]
					local arg = X('_arg', narg)
					local param = exp[i-1]
				--error('sjaakpot')
					waarde = substitueerzuinig(waarde, arg, param, maakvar)
				end
				assign(exp, waarde)
			end
		end
		]]

		-- opgelost
		if verbozeWaarde then
			print('=== WAARDE ===')
			print(exp2string(val))
			print()
		end

		return val,nil,bekend,exp2naam

		-- functie ontleding
		--[=[
		for eq in pairs(eqs) do
			if eq.f == [[=]] then
				local fx,val = eq[1],eq.a[2]
				-- (...) = f
				if isexp(fx) then
					-- (f x) = g
					if not isinvoer(fx.f) and not isinvoer(fx[1]) and bevat(val, fx[1]) then
						eq[1] = fx.f
						eq.a[2] = toexp {f='→', fx[1], val}
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

	do return end


	local v,f = oplos(ontleed'a = (x → x + 1)(2)', 'a')
	assert(v)
	assert(expmoes(v) == '+(2 1)' or expmoes(v) == '+(_arg(0) 1)',
		'v.b = '..expmoes(v)..' ≠ +(2 1)')

	assert(oplos(ontleed('a = 2'), 'a').v == '2')

	-- b = 2 + 2
	local v = oplos(ontleed('a = 2\na + 2 = b'), 'b')
	assert(v)
	assert(expmoes(v) == '+(2 2)',
		'v.b = '..expmoes(v)..' ≠ +(2 2)')

	do return end

	local v = oplos(ontleed('f(a) = f(b)\na = 2', 'b'))
	assert(v)
	assert(expmoes(v.b) == '2',
		'v.b = '..expmoes(v.b)..' ≠ 2')

	local v = oplos(toexp(ontleed('f(a + 1) = f(b + 1)\na = 2')), 'b')
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
