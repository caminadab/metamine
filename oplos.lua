require 'exp'
require 'combineer'
require 'isoleer'
require 'symbool'
require 'vhgraaf'
require 'defunc'
require 'bieb'
require 'rapport'
require 'graaf'

local bieb = bieb()

-- oplos: exp → waarde,fouten
function oplos(exp, voor, isdebug)
	local maakvar = maakvars()
	local maakindex = maakindices()
	local fouten = {}

	assert(fn(exp) == "⋀")

	local eqs = {}
	for i,v in ipairs(exp.a) do
		eqs[v] = true
	end

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
		return (tonumber(val) and tostring(val))
			or val == '_arg'
			or val == '_fn'
			or val == 'niets'
			or bieb[val] ~= nil -- KUCH KUCH
	end

	local nieuw, oud = {}, {}

	-- vind vars
	local vars = {} -- naam → eq
	local schaduw = {} -- naam → index
	for eq in pairs(eqs) do
		if fn(eq) == ':=' then
			local naam = atoom(arg0(eq))
			vars[naam] = eq
		end
	end

	-- bouw in.startvars
	local startvars = {o=X'[]'}
	local neq = X('=', 'in.startvars', startvars)
	for naam, eq in spairs(vars) do
		local index = maakindex()
		schaduw[naam] = index
		startvars[index] = arg1(eq)
	end
	eqs[neq] = true

	-- gesorteerde vars
	--for naam in spairs(schaduw) do
--		print(naam)
--	end

	-- herschrijf (a += b) naar (a := a' + b / fps)
	-- syntactic cocain
	for eq in pairs(eqs) do
		if fn(eq) == '+=' then
			local a, b = arg0(eq), arg1(eq)
			local B = X('+', a, X('·', b, 'dt'))
			local neq = X('|:=', a, X('⇒', X('≠', a, 'niets'), B))
			--assign(eq, neq)
			nieuw[neq] = true
			oud[eq] = true
		end

		for exp in boompairs(eq) do
			if exp ~= eq and fn(exp) == '+=' then
				local a, b = exp.a[1], exp.a[2]

				-- local neq = 
				--local neq = X(sym.ass, a, X(sym.map, maakvar(), X(sym.dan, X(sym.is, 'looptijd', '0'), b)))
				local B = X('+', kopieer(a), X('·', kopieer(b), 'dt'))
				local nexp = X(':=', a, B)
				--local nexp = X(':=', a, X('⇒', X('∧', X('¬', 'start'), X('≠', a, 'niets')), B, 'niets'))
				--print(e2s(neq))
				--oud[eq] = true
				--nieuw[neq] = true
				assign(exp, nexp)
			end
		end
	end

	-- a' is niet op momenten gedefinieerd maar alleen vlak ervoor

	-- herschrijf types
	for eq in pairs(eqs) do
		if fn(eq) == ':' then
			local neq = X('=', eq.a[1].v ..'Meer', eq.a[2])--X('alle', eq.a[2]))
			nieuw[neq] = true
		end
	end

	-- herschrijf (a(b) = c) naar
	-- bMeer = alle(b)
	-- a = b map (bMeer → c)
	for eq in pairs(eqs) do
		local arg = arg(eq) -- .a[1], .a[2]
		if arg and isobj(arg) and arg[1] and fn(arg[1]) == '_' then
			local ab,c = arg[1].a, arg[2]
			local A,B = ab[1], ab[2]
			local naam = ab[2].v
			if not naam then
				naam = '_arg'
			end
			local meer = naam..maakvar()
			local hulp = X('=', meer, naam..'Meer')
			local arghulp = X('=', naam, B)
			local neq = X('=', ab[1], X('_', 'map', X(',', meer, X('→', naam, c))))
			--print('NEQ', combineer(neq))
			--print('HULP', combineer(hulp))
			--print('ARGHULP', combineer(arghulp))
			nieuw[hulp] = true
			nieuw[neq] = true
			if naam ~= atoom(B) then
				nieuw[arghulp] = true
			end
		end
	end
	for eq in pairs(eqs) do
		if false and isfn(eq) and isfn(eq.a[1]) and false then --TODO and #eq[1] == 1 then
			local a, b, c  = eq.a[1].f, eq.a[1].a[1], eq.a[2]
			local neq = X(sym.cois, a, X(sym.map, b, c))
			local meq = X(sym.cois, a, X(sym.map, b, c))
			oud[eq] = true
			nieuw[neq] = true
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
			local fa = X(':', eq.a[1], X(X'..', eq.a[2], X'oneindig'))
			local fb = X(':', eq.a[2], X(X'..', X('-', X'oneindig'), eq.a[1]))
			nieuw[fa] = true
			nieuw[fb] = true
			oud[eq] = true
		end
	end

	local i = 0
	-- vind atomen
	for eq in pairs(eqs) do
		for exp in boompairs(eq) do
			if fn(exp) == '.' then
				local eq = X('=', exp.a, X('atoom', tostring(i)))
				i = i + 1
				nieuw[eq] = true
			end
		end
	end

	-- exp → eqs
	local function uitpak(exp, scope)
		for k,sub in subs(exp) do
			if fn(sub) == '=' or fn(sub) == ':=' then
				local neq = X('⇒', scope, sub)
				nieuw[neq] = true
			end
			if fn(sub) == '⇒' then
				local cond   = arg0(sub)
				local dan    = arg1(sub)
				local anders = arg2(sub)
				local block  = arg(dan)

				if fn(dan) == '⋀' then
					local subscope = X('∧', scope, arg0(sub))
					local block = arg(dan)
					uitpak(block, subscope)
				end
				if anders and fn(anders) == '⋀' then
					local block = arg(anders)
					local subnscope = X('∧', scope, X('¬', arg0(sub)))
					uitpak(block, subnscope)
				end
			end
		end
	end

	-- pak blokken uit
	for eq in pairs(eqs) do
		if fn(eq) == '⇒' then
			local cond   = arg0(eq)
			local dan    = arg1(eq)
			local anders = arg2(eq)
			oud[eq] = true
			if fn(dan) == '⋀' then
				local scope = cond
				local block = arg(dan)
				uitpak(block, scope)
			end
			if anders and fn(anders) == '⋀' then
				local block = arg(anders)
				local nscope = X('¬', cond)
				uitpak(block, nscope)
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
			
			--eq.f.v = '|='
			--if fn(eq.a[2]) == ':=' then
				--eq.f.v = '|:='
			--end
			local alt = eq.f
			local c = eq.a[1]
			local f = fn(eq.a[2])
			local a = eq.a[2].a[1]
			local b = eq.a[2].a[2]

			-- twee nieuwe
			local ae = eq.a[3] and eq.a[3].a[1] or X'niets'
			local be = eq.a[3] and eq.a[3].a[2] or X'niets'
			--assert(ae and be)
			local eqa = X('|'..f, a, X(sym.dan, c, b))--, be))
			local eqb = X('|'..f, b, X(sym.dan, c, a))--, ae))

			if isvar(a) then nieuw[eqa] = true end
			if isvar(b) and fn(eq.a[2]) == '=' then nieuw[eqb] = true end

			if eq.a[3] and (fn(eq.a[3]) == '=' or fn(eq.a[3]) == '|=' or fn(eq.a[3]) == ':=') then
				local e = X(sym.niet, c)
				local fe = fn(eq.a[3])
				local ae = eq.a[3].a[1]
				local be = eq.a[3].a[2]
				local eqa = X('|'..fe, ae, X(sym.dan, e, be))
				local eqb = X('|'..fe, be, X(sym.dan, e, ae))
				if isvar(a) then nieuw[eqa] = true end
				if isvar(b) and fn(eq.a[3]) == '=' then nieuw[eqb] = true end
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

	-- (a → a') als a een var is
	local function alsvar(exp)
		--print('EXP', e2s(exp))
		if isatoom(exp) then
			local naam = atoom(exp)
			if vars[naam] then
				exp.v = nil
				exp.f = X('index')
				assert(schaduw[naam], naam .. ' is geen variabele')
				exp.a = X(',', 'in.vars', tostring(schaduw[naam]-1))
			end
		end
		for key,sub in subs(exp) do
			if fn(exp) ~= ':=' then --or key ~= 1 then
				alsvar(sub)
			end
		end
	end
	
	-- verzamel |=
	local map = {} -- k → [v]
	local oud = {}
	for eq in pairs(eqs) do
		-- a |= b
		if fn(eq) == '|=' then
			local naam,alt = eq.a[1],eq.a[2]
			local key = e2s(naam)
			map[key] = map[key] or {}
			local alts = map[key]
			alts[#alts+1] = alt
			oud[eq] = true
		end
	end
	for eq in pairs(oud) do
		eqs[eq] = false
	end
	for naam,alts in pairs(map) do
		local eq
		if #alts == 1 then
			eq = X('=', naam, alts[1])
		else
			alts.o = X','
			eq = X('=', naam, X('|', alts))
			--nieuw[eq] = true
		end
		eqs[eq] = true
	end

	-- verzamel |:=
	local maakindex = maakindices()
	local map = {} -- k → [v]
	local oud = {}
	-- zorg dat allemaal bestaan
	for naam,eq in pairs(vars) do
		map[naam] = {}
	end
	for eq in pairs(eqs) do
		-- a |:= b
		if fn(eq) == '|:=' then
			local a,b = eq.a[1], eq.a[2]
			local naam = atoom(a)
			local v = map[naam]
			--print('VAAG', e2s(eq))

			if not v then
				local fout = oplosfout(eq.loc, '{code} is geen variabele', naam)
				fouten[#fouten+1] = fout
			else
				if eq.start then
					table.insert(v, 1, b)
				else
					v[#v+1] = b
				end
				oud[eq] = true
			end

		end
	end
	local eqs = complement(eqs, oud)
	for naam,alts in spairs(map) do
		if schaduw[naam] then

			alts.o = X','
			alsvar(alts)

			-- voeg de oude waarde toe 
			alts[#alts+1] = X('index', 'in.vars', tostring(schaduw[naam]-1))

			local index = schaduw[naam]
			assert(index, 'geen index voor variabele '..naam)
			local eq = X('=', 'uit.'..naam, X('|', alts))
			eqs[eq] = true
			local eq = X('=', naam, X('index', 'in.vars', tostring(schaduw[naam]-1)))
			eqs[eq] = true
		end
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
		local eq = X('=', X(naam), alts)
		eqs[eq] = true
	end

	-- verzamel ∈ en ∋
	local map = {} -- k → [v]
	local oud = {}
	for eq in pairs(eqs) do
		-- a ∐= b
		if isfn(eq) and (eq.f.v == 'bevat' or eq.f.v == 'zitin') then
			if eq.f.v == 'zitin' then
				eq.f, eq.a[1], eq.a[2] = X'bevat', eq.a[2], eq.a[1]
			end
			local a,b = eq.a[1], eq.a[2]
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
		alts.f = X'∪'
		local eq = X('=', X(naam), alts)
		eqs[eq] = true
	end

	-- herschrijf
	--   a'
	-- of
	--   a  (als a een var is)
	-- naar
	--   var(0)
	local nieuw = {}
	local oud = {}
	local maakindex = maakindices()
	for eq in pairs(eqs) do
		for exp in boompairs(eq) do
			local naam = exp.a and exp.a.v
			if (fn(exp) == "'" and naam) or schaduw[atoom(exp)] then
				naam = naam or atoom(exp)
				--schaduw[naam] = maakindex() 
				-- a' ↦ var(0)
				--assert(schaduw[naam], 'onbekende variabele: '..naam)
				-- onbekende variabele
				if not schaduw[naam] then
					--local def = bron2def[punt]
					local fout = oplosfout(exp.loc, '{code} is geen variabele', punt)
					fouten[#fouten+1] = fout
				else
					--assign(exp, X('_', 'in.vars', schaduw[naam]))
					--exp.v = nil
					--exp.f = X('_')
					--exp.a = X(',', 'in.vars', schaduw[naam])
					--exp.f = X'in.vars'
					--exp.a = X(schaduw[naam])
				end
			end
		end
	end

	-- uit (jaja!)
	local ivars = {o=X'[]'}
	for var in spairs(vars) do
		local i = schaduw[var]
		ivars[i] = X('uit.'..var)
	end
	local eq = X('=', 'uit.vars', ivars)
	nieuw[eq] = true

	eqs = unie(eqs, nieuw)
	eqs = complement(eqs, oud)

	-- functies
	local nieuw = {}
	local afval = {}
	local argindex2naam = {}

	-- herschrijf a→a+1 naar _fn(0 +(_arg(0) 1))
	for eq in pairs(eqs) do
		for lam in boompairs(eq) do
			-- 
			if fn(lam) == '→' then
				local inn,uit = lam.a[1], lam.a[2]
				local argindex = tostring(maakindex())

				-- pas vergelijking aan
				for i in pairs(lam) do lam[i] = nil end
				local var = maakvar()
				lam.f = X('_fn')
				lam.a = X(',', argindex, uit)
				local naam = X('_arg', argindex)

				-- complexe parameters
				local paramhulp = X('=', naam, inn)
				nieuw[paramhulp] = true
				argindex2naam[argindex] = inn
			end
		end
	end
	for eq in pairs(nieuw) do eqs[eq] = true end

	-- los vergelijkingen op
	-- → multimap = lijst(:=(A,B))
	local subst = {}
	for eq in pairs(eqs) do
		--print('JA', e2s(eq))
		if fn(eq) == "=" then
			for naam in pairs(var(eq,invoer)) do
				--if naam ~= eq[1] and naam ~= eq.a[2] then
				if bieb[naam] == nil then
					--if verboos then print('Probeer', naam, toexp(eq)) end
					--print('NAAM', e2s(naam))
					local waarde = isoleer(eq, naam)
					if waarde then
						local eq = X(':=', naam, waarde)
						subst[eq] = true
						--if verbozeOplos then print('SUBST', exp2string(eq)) end
					end
				end
			end
		end
	end

	if verbozeKennis then
		print('=== VOORGEKAUWD ===')
		local teqs = {}
		for eq in pairs(subst) do
			teqs[#teqs+1] = combineer(eq)
		end
		table.sort(teqs)
		for i,teq in ipairs(teqs) do
			print(teq)
		end
		print()
	end

	-- maak graaf
	local kennisgraaf = vhgraaf()
	local pijl2subst = {}
	local bron2def = {}
	local alfout = {}
	for subst in pairs(subst) do
		local naam,waarde = subst.a[1],subst.a[2]
		local bron0 = var(waarde,invoer)
		local bron = {}
		local ok = true
		for k in pairs(bron0) do -- alleen naam is nodig
			--assert(type(k.v) == 'string', see(k.v))
			if k.v == naam.v and not alfout[k.v] then
				alfout[k.v] = true
				ok = false
				local fout = oplosfout(k.loc, '{exp} is recursief gedefinieerd', k)
				fouten[#fouten+1] = fout
			end
			bron[k.v] = true
			bron2def[k.v] = k
		end
		if ok then
			local pijl = kennisgraaf:link(bron, naam.v)
			pijl2subst[pijl] = subst
		end
	end

	-- ULTIEME KENNISGRAAF
	if verbozeKennisgraaf then
		print(kennisgraaf:tekst())
	end

	local stroom,halfvan,halfnaar = kennisgraaf:sorteer(invoer,voor)

	if not stroom then
		if false then
			print('HALV VAN')
			print(halfvan:tekst())
			print('HALV NAAR')
			print(halfnaar:tekst())
		end
		--[[
		local a = stroom2html(halfvan)
		local b = stroom2html(halfnaar)
		file('halfvan.html', a)
		file('halfnaar.html', b)
		]]

		for punt in pairs(halfnaar.begin) do
			if not halfvan.punten[punt] then
				local def = bron2def[punt]
				local fout = oplosfout(def.loc, '{code} is ongedefinieerd', punt)
				fouten[#fouten+1] = fout
			end
		end

		if #fouten == 0 then
			--print(halfnaar:tekst())
			
			local fout = oplosfout(nergens, 'kon niet oplossen')
			fouten[#fouten+1] = fout
		end
		return false, fouten, {}
	end
	local substs = stroom:topologisch()

	local val = X(voor)
	local perexp = {[voor] = set(val)}
	local varmap = {}

	-- le grande substituutsjon
	for i=#substs,1,-1 do
		local sub = pijl2subst[substs[i]]
		--print('subst', combineer(sub))
		local van,naar = arg0(sub), arg1(sub)
		local naam = atoom(van)

		-- assign
		if perexp[naam] then
			for exp in pairs(perexp[naam]) do
				assign(exp, naar)
			end

			for exp in pairs(perexp[naam]) do
				-- registreer nieuwe
				for sub in boompairs(exp) do
					local naam = atoom(sub)
					if naam and not tonumber(naam) then
						perexp[naam] = perexp[naam] or {}
						perexp[naam][sub] = true
						--print('reg', naam, sub)
					end
				end
				break
			end

		end
		
		varmap[van] = naar
	end

	-- check args
	-- args: set
	local al = {}
	local function check(exp, def)
		if al[exp] then return end
		al[exp] = true
		assert(def)
		if fn(exp) == '_fn' then
			local num = atoom(arg0(exp))
			def[num] = true
			for k, sub in subs(exp) do
				check(sub, def)
			end
			def[num] = false
		elseif fn(exp) == '_arg' then
			local num = atoom(arg(exp))
			if not def[num] then
				local naam = argindex2naam[num]
				local fout = oplosfout(naam.loc, '{exp} is ongedefinieerd buiten functie', naam)
				fouten[#fouten+1] = fout
			end
		else
			for k, sub in subs(exp) do
				if not al[sub] then
					check(sub, def)
				end
			end
		end
	end
	check(val, {})
	if #fouten > 0 then
		return nil, fouten, varmap
	end

	return val,{},varmap

end
