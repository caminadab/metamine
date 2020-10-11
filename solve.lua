require 'exp'
require 'deparse'
require 'isolate'
require 'symbol'
require 'hyperflow'
require 'defunc'
require 'lib'
require 'rapport'
require 'graph'

local lib = lib()

-- solve: exp → waarde,fouten
function solve(exp, voor, isdebug)
	local makevar = makevars()
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
			or lib[val] ~= nil -- KUCH KUCH
	end

	local nieuw, oud = {}, {}

	-- vind vars
	local vars = {} -- name → eq
	local schaduw = {} -- name → index
	for eq in pairs(eqs) do
		if fn(eq) == ':=' then
			local name = atom(arg0(eq))
			vars[name] = eq
		end
	end

	-- bouw in.startvars
	local startvars = {o=X'[]'}
	local neq = X('=', 'in.startvars', startvars)
	for name, eq in spairs(vars) do
		local index = maakindex()
		schaduw[name] = index
		startvars[index] = arg1(eq)
	end
	eqs[neq] = true

	-- gesorteerde vars
	--for name in spairs(schaduw) do
--		print(name)
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

		for exp in treepairs(eq) do
			if exp ~= eq and fn(exp) == '+=' then
				local a, b = exp.a[1], exp.a[2]

				-- local neq = 
				--local neq = X(sym.ass, a, X(sym.map, makevar(), X(sym.dan, X(sym.is, 'looptijd', '0'), b)))
				local B = X('+', copy(a), X('·', copy(b), 'dt'))
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
			local name = ab[2].v
			if not name then
				name = '_arg'
			end
			local meer = name..makevar()
			local hulp = X('=', meer, name..'Meer')
			local arghulp = X('=', name, B)
			local neq = X('=', ab[1], X('_', 'map', X(',', meer, X('→', name, c))))
			--print('NEQ', deparse(neq))
			--print('HULP', deparse(hulp))
			--print('ARGHULP', deparse(arghulp))
			nieuw[hulp] = true
			nieuw[neq] = true
			if name ~= atom(B) then
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
		if false and isfn(eq) and eq.a[2] and isfn(eq.a[2]) --[[and isatom(eq.a[2].f)]] and isatom(eq.a.a[2].a[1]) and #eq.a[2] == 1 then
			local a, b, c  = eq.a[2].f, eq.a[2].a[1], eq.a[1]
			local neq = X(sym.cois, a, X(sym.map, b, c))
			--oud[eq] = true
			nieuw[neq] = true
		end
	end

	-- herschrijf (a ||= b) naar (a |= a' || b)
	for eq in pairs(eqs) do
		for exp in treepairs(eq) do
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
		for exp in treepairs(eq) do
			if fn(exp) == '.' then
				local eq = X('=', exp.a, X('atom', tostring(i)))
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
		if isatom(exp) then
			local name = atom(exp)
			if vars[name] then
				exp.v = nil
				exp.f = X('index')
				assert(schaduw[name], name .. ' is geen variabele')
				exp.a = X(',', 'in.vars', tostring(schaduw[name]-1))
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
			local name,alt = eq.a[1],eq.a[2]
			local key = e2s(name)
			map[key] = map[key] or {}
			local alts = map[key]
			alts[#alts+1] = alt
			oud[eq] = true
		end
	end
	for eq in pairs(oud) do
		eqs[eq] = false
	end
	for name,alts in pairs(map) do
		local eq
		if #alts == 1 then
			eq = X('=', name, alts[1])
		else
			alts.o = X','
			eq = X('=', name, X('|', alts))
			--nieuw[eq] = true
		end
		eqs[eq] = true
	end

	-- verzamel |:=
	local maakindex = maakindices()
	local map = {} -- k → [v]
	local oud = {}
	-- zorg dat allemaal bestaan
	for name,eq in pairs(vars) do
		map[name] = {}
	end
	for eq in pairs(eqs) do
		-- a |:= b
		if fn(eq) == '|:=' then
			local a,b = eq.a[1], eq.a[2]
			local name = atom(a)
			local v = map[name]
			--print('VAAG', e2s(eq))

			if not v then
				local fout = solvefout(eq.loc, '{code} is geen variabele', name)
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
	for name,alts in spairs(map) do
		if schaduw[name] then

			alts.o = X','
			alsvar(alts)

			-- voeg de oude waarde toe 
			alts[#alts+1] = X('index', 'in.vars', tostring(schaduw[name]-1))

			local index = schaduw[name]
			assert(index, 'geen index voor variabele '..name)
			local eq = X('=', 'uit.'..name, X('|', alts))
			eqs[eq] = true
			local eq = X('=', name, X('index', 'in.vars', tostring(schaduw[name]-1)))
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
	for name,alts in pairs(map) do
		alts.f = X'co'
		if #alts == 1 then
			alts = alts.a[1]
		end
		local eq = X('=', X(name), alts)
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
	for name,alts in pairs(map) do
		alts.f = X'∪'
		local eq = X('=', X(name), alts)
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
		for exp in treepairs(eq) do
			local name = exp.a and exp.a.v
			if (fn(exp) == "'" and name) or schaduw[atom(exp)] then
				name = name or atom(exp)
				--schaduw[name] = maakindex() 
				-- a' ↦ var(0)
				--assert(schaduw[name], 'onbekende variabele: '..name)
				-- onbekende variabele
				if not schaduw[name] then
					--local def = bron2def[punt]
					local fout = solvefout(exp.loc, '{code} is geen variabele', punt)
					fouten[#fouten+1] = fout
				else
					--assign(exp, X('_', 'in.vars', schaduw[name]))
					--exp.v = nil
					--exp.f = X('_')
					--exp.a = X(',', 'in.vars', schaduw[name])
					--exp.f = X'in.vars'
					--exp.a = X(schaduw[name])
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
	local argindex2name = {}

	-- herschrijf a→a+1 naar _fn(0 +(_arg(0) 1))
	for eq in pairs(eqs) do
		for lam in treepairs(eq) do
			-- 
			if fn(lam) == '→' then
				local inn,uit = lam.a[1], lam.a[2]
				local argindex = tostring(maakindex())

				-- pas vergelijking aan
				for i in pairs(lam) do lam[i] = nil end
				local var = makevar()
				lam.f = X('_fn')
				lam.a = X(',', argindex, uit)
				local name = X('_arg', argindex)

				-- complexe parameters
				local paramhulp = X('=', name, inn)
				nieuw[paramhulp] = true
				argindex2name[argindex] = inn
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
			for name in pairs(var(eq,invoer)) do
				--if name ~= eq[1] and name ~= eq.a[2] then
				if lib[name] == nil then
					--if verboos then print('Probeer', name, toexp(eq)) end
					--print('NAAM', e2s(name))
					local waarde = isolate(eq, name)
					if waarde then
						local eq = X(':=', name, waarde)
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
			teqs[#teqs+1] = deparse(eq)
		end
		table.sort(teqs)
		for i,teq in ipairs(teqs) do
			print(teq)
		end
		print()
	end

	-- maak graph
	local kennisgraph = hyperflow()
	local pijl2subst = {}
	local bron2def = {}
	local alfout = {}
	for subst in pairs(subst) do
		local name,waarde = subst.a[1],subst.a[2]
		local bron0 = var(waarde,invoer)
		local bron = {}
		local ok = true
		for k in pairs(bron0) do -- alleen name is nodig
			--assert(type(k.v) == 'string', see(k.v))
			if k.v == name.v and not alfout[k.v] then
				alfout[k.v] = true
				ok = false
				local fout = solvefout(k.loc, '{exp} is recursief gedefinieerd', k)
				fouten[#fouten+1] = fout
			end
			bron[k.v] = true
			bron2def[k.v] = k
		end
		if ok then
			local pijl = kennisgraph:link(bron, name.v)
			pijl2subst[pijl] = subst
		end
	end

	-- ULTIEME KENNISGRAAF
	if verbozeKennisgraph then
		print(kennisgraph:text())
	end

	local flow,halfvan,halfnaar = kennisgraph:sorteer(invoer,voor)

	if not flow then
		if false then
			print('HALV VAN')
			print(halfvan:text())
			print('HALV NAAR')
			print(halfnaar:text())
		end
		--[[
		local a = flow2html(halfvan)
		local b = flow2html(halfnaar)
		file('halfvan.html', a)
		file('halfnaar.html', b)
		]]

		for punt in pairs(halfnaar.begin) do
			if not halfvan.punten[punt] then
				local def = bron2def[punt]
				local fout = solvefout(def.loc, '{code} is ongedefinieerd', punt)
				fouten[#fouten+1] = fout
			end
		end

		if #fouten == 0 then
			--print(halfnaar:text())
			
			local fout = solvefout(nergens, 'kon niet solvesen')
			fouten[#fouten+1] = fout
		end
		return false, fouten, {}
	end
	local substs = flow:topologisch()

	local val = X(voor)
	local perexp = {[voor] = set(val)}
	local varmap = {}

	-- le grande substituutsjon
	for i=#substs,1,-1 do
		local sub = pijl2subst[substs[i]]
		--print('subst', deparse(sub))
		local van,naar = arg0(sub), arg1(sub)
		local name = atom(van)

		-- assign
		if perexp[name] then
			for exp in pairs(perexp[name]) do
				assign(exp, naar)
			end

			for exp in pairs(perexp[name]) do
				-- registreer nieuwe
				for sub in treepairs(exp) do
					local name = atom(sub)
					if name and not tonumber(name) then
						perexp[name] = perexp[name] or {}
						perexp[name][sub] = true
						--print('reg', name, sub)
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
			local num = atom(arg0(exp))
			def[num] = true
			for k, sub in subs(exp) do
				check(sub, def)
			end
			def[num] = false
		elseif fn(exp) == '_arg' then
			local num = atom(arg(exp))
			if not def[num] then
				local name = argindex2name[num]
				local fout = solvefout(name.loc, '{exp} is ongedefinieerd buiten functie', name)
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
