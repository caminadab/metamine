require 'exp'
require 'combineer'
require 'isoleer'
require 'symbool'
require 'vhgraaf'
require 'bieb'
require 'rapport'

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
	local fouten = {}
	if isatoom(exp) then return X'ZWARE FOUT',fouten end -- KAN NIET
	if exp.fn.v == [[=]] or exp.fn.v == [[EN]] then
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
			if type(val) == 'string' and val:sub(1,1) == '_' then -- TODO
				return true
			end

			if type(val) == 'table' then return false end
			return tonumber(val)
				or string.upper(val or '???')==val
				or val == 'standaardinvoer' -- kuch...
				or val == '_arg'
				or val == '_fn'
				or bieb[val] ~= nil -- KUCH KUCH
		end


		local nieuw, oud = {}, {}

		-- a' is niet op momenten gedefinieerd maar alleen vlak ervoor

		-- herschrijf (a := b) naar (a |= (start ⇒ b) | a')
		for eq in pairs(eqs) do
			if eq.fn and eq.fn.v == ':=' then
				--oud[eq] = true
				local a, b = eq[1], eq[2]
				--eq.fn,eq[1],eq[2] = sym.altis, a, 

				local neq = X(sym.altis, a, X(sym.alt, X(sym.dan, sym.start, b), X(sym.oud, a)))
				oud[eq] = true
				nieuw[neq] = true
			end
		end

		-- herschrijf (a(b) = c) naar (a ∐= b ↦ c)
		for eq in pairs(eqs) do
			--if isfn(eq) and isfn(eq[1]) --[[and isatoom(eq[1].fn)]] and isatoom(eq[1][1]) and #eq[1] == 1 then
			if isfn(eq) and isfn(eq[1]) and #eq[1] == 1 then
				local a, b, c  = eq[1].fn, eq[1][1], eq[2]
				local neq = X(sym.cois, a, X(sym.map, b, c))
				oud[eq] = true
				nieuw[neq] = true
				--error(exp2string(neq))
			end

		-- herschrijf (c = a(b)) naar (a ∐= b ↦ c)
			if isfn(eq) and isfn(eq[2]) --[[and isatoom(eq[2].fn)]] and isatoom(eq[2][1]) and #eq[2] == 1 then
				local a, b, c  = eq[2].fn, eq[2][1], eq[1]
				local neq = X(sym.cois, a, X(sym.maplet, b, c))
				--oud[eq] = true
				nieuw[neq] = true
			end
		end

		-- herschrijf (a ||= b) naar (a |= a' || b)
		for eq in pairs(eqs) do
			for exp in boompairs(eq) do
				if exp.fn and exp.fn.v == "||=" then --== sym.catass then
					local a, b = exp[1], exp[2]
					exp.fn, exp[1], exp[2] = sym.altis, a, X(sym.cat, X(sym.oud, a), b)
				end
			end
		end

		-- herschrijf (a < b) → (a: (b..∞) ∧ b: (-∞ .. a))
		for eq in pairs(eqs) do
			if isfn(eq) and eq.fn.v == '>' then
				eq.fn.v,fn,eq[2],eq[1] = '<',eq[1],eq[2]
			end
			if isfn(eq) and eq.fn.v == '<' then
				local fa = X(X':', eq[1], X(X'..', eq[2], X'oneindig'))
				local fb = X(X':', eq[2], X(X'..', X(X'-', X'oneindig'), eq[1]))
				nieuw[fa] = true
				nieuw[fb] = true
				oud[eq] = true
			end
		end

		local i = 0
		-- vind atomen
		for eq in pairs(eqs) do
			for exp in boompairs(eq) do
				if isfn(exp) and exp.fn.v == '.' then
					exp.fn, exp[1], exp[2] = X'=', exp[1], {fn=X'atoom', X(tostring(i)) }
					i = i + 1
				end
			end
		end

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
			if fn(eq) == '=>' and (fn(eq[2]) == '=' or fn(eq[2]) == '|=') then
				eq.fn.v = '|='
				local c = eq[1]
				local a = eq[2][1]
				local b = eq[2][2]

				-- twee nieuwe
				local ae = eq[3] and eq[3][1]
				local be = eq[3] and eq[3][2]
				local eqa = X{fn=sym.altis, a, {fn=sym.dan, c, b, be}}
				local eqb = X{fn=sym.altis, b, {fn=sym.dan, c, a, ae}}
				nieuw[eqa] = true
				nieuw[eqb] = true

				if false and eq[3] and (fn(eq[3]) == '=' or fn(eq[3]) == '|=') then
					local e = {fn=sym.niet, c}
					local ae = eq[3][1]
					local be = eq[3][2]
					local eqa = {fn=sym.altis, ae, {fn=sym.dan, e, be}}
					local eqb = {fn=sym.altis, be, {fn=sym.dan, e, ae}}
					nieuw[eqa] = true
					nieuw[eqb] = true
				end
			end
		end
		eqs = complement(eqs, oud)
		eqs = unie(eqs, nieuw)
		nieuw = {}
		oud = {}

		-- herschrijf  f(a) = a + 1
		-- naar        f ∐= a → a + 1
		for eq in pairs(eqs) do
			if false and isfn(eq) and isfn(eq[1]) and #eq[1] == 1 then
				local vrij = var(eq[1])
				for naam in pairs(vrij) do
					if bevat(eq[2], naam) then
						eq[1],eq[2] = eq[1].fn, {fn=X'->', eq[1][1], eq[2]}
						print('HERSCHRIJF', exp2string(eq))
						break
					end
				end
			end
		end

		eqs = complement(eqs, oud)
		eqs = unie(eqs, nieuw)

		-- verzamel |=
		local map = {} -- k → [v]
		local oud = {}
		for eq in pairs(eqs) do
			-- a |= b
			if isfn(eq) and eq.fn.v == '|=' then
				local a,b = eq[1],eq[2]
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
			alts.fn = X'|'
			if #alts == 1 then
				alts = alts[1]
			end
			local eq = {fn=X'=', X(naam), alts}
			eqs[eq] = true
		end

		-- verzamel ∐=
		local map = {} -- k → [v]
		local oud = {}
		for eq in pairs(eqs) do
			-- a ∐= b
			if isfn(eq) and eq.fn.v == 'co=' then
				local a,b = eq[1],eq[2]
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
			alts.fn = X'co'
			if #alts == 1 then
				alts = alts[1]
			end
			local eq = {fn=X'=', X(naam), alts}
			eqs[eq] = true
		end

		-- verzamel ∈ en ∋
		local map = {} -- k → [v]
		local oud = {}
		for eq in pairs(eqs) do
			-- a ∐= b
			if isfn(eq) and (eq.fn.v == 'bevat' or eq.fn.v == 'zitin') then
				if eq.fn.v == 'zitin' then
					eq.fn,eq[1],eq[2] = X'bevat',eq[2],eq[1]
				end
				local a,b = eq[1],eq[2]
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
			alts.fn = X'UNIE'
			local eq = {fn=X'=', X(naam), alts}
			eqs[eq] = true
		end

		-- herschrijf
		--   a = f(a')
		-- naar
		--   a = (herhaal (a' → a))(niets)
		local nieuw = {}
		local oud = {}
		for eq in pairs(eqs) do
			if isfn(eq) and isatoom(eq[1]) and eq.fn.v == '=' then
				local a,b = eq[1],eq[2]
				for node in boompairs(b) do
					if isfn(node) and node.fn.v == "'" and node[1].v == a.v then
						local oude = X(node[1].v .. '_oud')
						b = substitueer(b, node, oude)
						node.fn = nil
						node.v = a.v
						eqn = X('=', a, X(X('herhaal', X('->', oude, b)), 'niets'))
						oud[eq] = true
						nieuw[eqn] = true
					end
				end
			end
		end

		eqs = unie(eqs, nieuw)
		eqs = complement(eqs, oud)

		-- uit = (start ⇒ "ok") | (looptijd = 1 ⇒ uit' || "ok")

		-- functies
		local aantal = 0
		local nieuw = {}
		local afval = {}
		for eq in pairs(eqs) do
			for lam in punten(eq) do

				-- 
				if fn(lam) == '->' then
					local inn,uit = lam[1],lam[2]
					local params
					if isexp(inn) and inn.fn.v == ',' and false then
						params = inn
					else
						params = {inn}
					end

					-- pas vergelijking aan
					lam.fn = X'_fn'
					for i in ipairs(lam) do lam[i] = nil end

					-- complexe parameters
					for i,param in ipairs(params) do
						if not isatoom(param) or true then
							--local naam = X('_'..varnaam(aantal))
							local naam = X('_arg', tostring(aantal))
							params[i] = naam
							lam[i] = X(tostring(aantal))
							local paramhulp = {fn=X'=', naam, param}
							nieuw[paramhulp] = true -- HIER!

							-- pas vergelijking aan
							--lam[1] = naam
							--for i,v in ipairs(lam) do lam[i] = nil end
							--for k,v in pairs(uit) do lam[k] = v end

						end
						aantal = aantal + 1
					end
					lam[#lam+1] = uit
				end
			end
		end
		for eq in pairs(nieuw) do eqs[eq] = true end

		-- los vergelijkingen op
		-- -> multimap = lijst(:=(A,B))
		local subst = {}
		for eq in pairs(eqs) do
			if isfn(eq) and eq.fn.v == [[=]] then
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
			local naam,waarde = subst[1],subst[2]
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
					local fout = {
						msg = loctekst(def.loc) .. ': ' .. color.brightred .. "Oplosfout: " .. color.yellow .. tostring(punt) .. color.white .. " is ongedefinieerd"
					}
					fouten[#fouten+1] = fout
				end
			end
			return false, fouten, {}
		end
		local substs = stroom:topologisch()
		if not substs then
			-- dit is een zware fout...
			return false, 'kon niet topologisch sorteren', bekend, {}
		end
		-- lijst(subst)

		-- op te lossen waarde, staat die niet altijd laatste (;
		--TODOlocal val = voor
		local val = X(voor)--X'uit'
		local exp2naam = {}

		local exp2naam = {}
		for i=#substs,1,-1 do
			local sub = pijl2subst[substs[i]]
			local naam,exp = sub[1],sub[2]
			local val0 = val
			val = substitueer(val0, naam, exp)
			--exp2naam[val0] = naam
			--print('SUBST', exp2string(val0), exp2string(naam), exp2string(exp), exp2string(val))
			if verboos then
				print('SUBST', naam.v)
			end

			exp2naam[naam.v] = exp
			local n2e = {}
			for k,v in pairs(exp2naam) do
				n2e[k] = substitueer(v, naam, exp)
			end
			exp2naam = n2e
		end

		-- nog ff sneaken
		-- functies toepassen
		--error(exp2string(val))
		for exp in boompairs(val) do
			if isfn(exp) and fn(exp.fn) == '_fn' then
				local narg, waarde = exp.fn[1], exp.fn[2]
				local arg = X('_arg', narg)
				local param = exp[1]
				--error('sjaakpot')
				local nexp = substitueer(waarde, arg, param)
				assign(exp, nexp)
			end
		end

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

	return exp,nil,exp2naam
end

if test then
	require 'util'
	require 'ontleed'

	local v,f = oplos(ontleed'a = (x → x + 1)(2)', 'a')
	assert(v)
	assert(expmoes(v) == '+(2 1)',
		'v.b = '..expmoes(v)..' ≠ 2')

	do return end

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
