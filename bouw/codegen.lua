require 'exp'
require 'util'
require 'graaf'
require 'symbool'
require 'combineer'

require 'bouw.blok'

--[[

f(x) = x + 1
exitcode = f(3)


start:
	a := 3
	b := call f, 3
	ret b
-> f
<- f

f:
	y := _arg 0
	ret := y + 1
-> start
<- start
	
]]

-- diepte bepalen
local function peil(waarde)
	-- bepaal diepte
	local diepte = {}

	for exp in boompairsdfs(waarde) do
		-- bladwaarden krijgen 1
		if isatoom(exp) then
			diepte[exp] = 1
		else
			diepte[exp] = 0
			local gelijk = false
			-- bepaal rec diepte
			for i,v in ipairs(exp) do
				if diepte[v] > diepte[exp] then gelijk = false
				elseif diepte[v] == diepte[exp] then gelijk = true
				end
				diepte[exp] = math.max(diepte[exp], diepte[v])
			end
			-- als ze zelfde zijn is er 1 extra nodig (voor phi?)
			if gelijk
				then diepte[exp] = diepte[exp] + 1
			end
		end
	end
	
	return diepte
end

local postop = set("%","!",".","'")
local binop  = set("+","·","/","^"," ","∨","∧","×","..","→","∘","_","‖","⇒",">","≥","=","≠","≈","≤","<",":=","+=","|:=", "∪","∩",":","∈", "^i", "^f")
local unop   = set("-","#","¬","Σ","|","%","√","!")

function codegen(exp, maakvar)
	local blokken = {} -- naam → blok
	local maakvar = maakvar or maakvars()
	local procindex = maakindices()
	local funcindex = maakindices()

	local function maakproc()
		return 'p'..procindex()
	end

	local function maakfunc()
		return 'fn'..funcindex()
	end

	-- running block
	local blok = maakblok(X'init', {}, X'stop')
	blokken.init = blok

	local con
	local al = {}
	--setmetatable(al, {__newindex = function (...) print(...) ; rawset(...); print(debug.traceback()) end})
	local gen2bron = {} -- lijn → lijn

	local function arg(exp)
		local arg
		if exp.v and exp.v:sub(1,1) == '~' then
			--error'NEE'
			--print('ARG AL', exp.v)
			return al[exp.v]
		end
		if fn(exp) == '[]' then
			arg = con(exp)
		elseif fn(exp) == '[]u' then
			--error'OK'
			arg = con(exp)
		elseif isfn(exp) then
			arg = con(exp)
		elseif isobj(exp) then
			arg = con(exp)
		elseif exp.v == string.upper(exp.v) and not tonumber(exp.v) then
			arg = con(exp)
		elseif not tonumber(exp.v) then
			arg = con(exp)
		else
			arg = (exp)
		end
		arg.ref = exp.ref
		return arg
	end

	function mkstat(stat, ret)
		stat.loc = exp.loc
		--stat.code = exp.code
		--stat.ref = ret.ref

		local val = stat.a[2]
		if verbozeIntermediair then
			--print('  '..combineer(stat)..'  '..(val.ref and val.ref.v or ''))
		end
		--print(e2s(stat), val.ref)
		if not val.ref then
			--val.ref = X('~'..maakvar())
		end
		-- TODO WAT IS AL?
		-- TODO VERKEERD GEZET
		-- TODO HOI
		if val.ref and not al[val.ref.v] then
			--print(val.ref.v .. ' -> '..e2s(stat[1]))
			--print('REF', val.ref.v, e2s(stat[1]))
			--error(val.ref)
			--al[ret.v] = val.ref
			al[val.ref.v] = stat.a[1]
			--print(debug.traceback())
			assert(isatoom(stat.a[1]))
			--print(e2s(stat), e2s(stat[1]))
			--print('REG:', val.ref.v, e2s(stat[1]))
			--al[ret.v] = assert(stat[2].ref, 'statement heeft geen referentiecode: '..e2s(stat))
		end
		if not val.ref and isfn(val) then
			--error('geen referentie voor '..e2s(val))
		end
		table.insert(blok.stats, stat)
		gen2bron[#blok.stats] = stat.loc
		return ret
	end

	function con(exp,ret)
		--print('CON', combineer(exp))
		local fw = {} --f=exp.f}
		local ret = ret or X(maakvar())
		local stat = X(':=', ret, fw)

		if isatoom(exp) and exp.v:sub(1,1) == '~' then
			--error('ok'.. exp.v)
			local stat = X(':=', ret, (assert(al[exp.v], 'niet geregistreerd: '..exp.v))) --assert(al[exp.v:sub(1,-2)], exp.v))
			--error('OK')
			stat.loc = exp.loc
			stat.code = assert(exp.code)
			return mkstat(stat, ret)
		
		-- functie
		elseif fn(exp) == '_' and fn(arg0(exp)) == '_fn' then
			--assert(exp.ref)
			--al = {}
			local naam = X(maakfunc())
			local waarde = arg1(exp)
			local arg = X'_arg' --exp.a[2]
			local keys = {}
			for k in pairs(exp) do keys[k] = true end
			for k in pairs(keys) do exp[k] = nil end
			exp.v = naam.v
			local bfn = maakblok(naam, {}, X('ret', '?'))
			local b = blok
			blok = bfn
			--al[ret.v] = naam
			--waarde.ref = 
			--print('FN AL', ret.v, e2s(stat))
			--stat[2].ref = assert(exp.ref)

			--[[
			-- argumenten
			local nargs = #waarde - 1
			for i,arg in ipairs(args) do
				local argvan = X('_arg', arg)
				local argnaar = X('_arg'..(i-1))

				local argalt = X(argnaar.v..arg.v)

				-- veilig stellen...
				--waarde = substitueerzuinig(waarde, argnaar, argalt, maakvar)
				--print('JA!', e2s(argvan), e2s(argnaar)) -- PRINT

				waarde = substitueerzuinig(waarde, argvan, argnaar, maakvar)
			end
			-- is alles eruit?
			for exp in boompairs(waarde) do
				if fn(exp) == '_arg' then
				print('FOUTE BOEL!', e2s(exp)) -- PRINT
				end
			end
			]]

			local res = con(waarde)
			blok.epiloog.a[1] = res

			--graaf:punt(bfn)
			blokken[bfn.naam.v] = bfn

			blok = b
			local stat = X(':=', ret, naam)
			stat.loc = exp.loc
			stat.code = exp.code
			stat.a[2].ref = exp.ref --naam
			al[ret.v] = naam
			--table.insert(blok.stats, stat)
			mkstat(stat, ret)

		-- alsdan!
		elseif fn(exp) == '⇒' then
			local blok0 = blok
			local eals, edan, eanders = exp.a[1], exp.a[2], exp.a[3]
			
			-- procnamen
			local dan = X(maakproc())
			local anders = X(maakproc())
			local phi = X(maakproc())

			-- phi (eindcontinuatie)
			local bphi = maakblok(phi, {}, blok0.epiloog) -- krijgt zelfde eind
			blokken[phi.v] = bphi

			-- als
			blok = blok0
			local econd = con(eals)
			-- sprong
			blok.epiloog = X('ga', econd, dan, anders)

			-- dan
			local bdan = maakblok(dan, {}, X('ga', phi))
			blokken[dan.v] = bdan
			blok = bdan
			local rdan = con(edan)

			-- anders
			local banders = maakblok(anders, {}, X('ga', phi))
			blokken[anders.v] = banders
			blok = banders

			local randers = '???'
			if eanders then
				randers = con(eanders,rdan)
			end

			-- daadwerkelijke '=>'
			local stat = X(':=', ret, rdan)
			stat.a[2].ref = exp.ref
			al[ret.v] = rdan
			blok = bphi
			mkstat(stat, ret)

		elseif tonumber(exp) then
			stat.a[2] = X(tostring(exp))
			stat.loc = exp.loc
			stat.code = exp.code
			mkstat(stat, ret)
			stat.a[2].ref = exp.ref

		-- a := b
		elseif isatoom(exp) then
			stat.a[2] = exp
			stat.loc = exp.loc
			stat.code = exp.code
			--al[exp] = stat[2]
			stat.a[2].ref = exp.ref
			mkstat(stat, ret)

		-- normale statement (TODO sorteer)
		else
			local fw = {f=exp.f}
			local ret = ret or X(maakvar())
			local stat = X(':=', ret, fw)
			if not exp.f and not exp.o then error(e2s(exp)) end

			if exp.f and exp.f.v:sub(1,1) == '~' then
				fw.f = assert(al[exp.f.v], 'onbekende ref: '..exp.f.v)
			end

			if binop[fn(exp)] then
				fw.f = exp.f
				fw.a = X(',', arg(exp.a[1]), arg(exp.a[2]))
				--print('ARGS', combineer(exp.a))
				--print('FW', combineer(fw))

			elseif unop[fn(exp)] then
				fw.f = exp.f
				fw.a = arg(exp.a)

			elseif fn(exp) == '_' then
				fw.f = arg(exp.f)
				fw.a = arg(exp.a)

			elseif isobj(exp) then
				fw.o = exp.o
				for i,v in ipairs(exp) do
					fw[i] = arg(v)
				end

			elseif fn(exp) == '_arg' then
				--error'OK'

				--exp.f = nil
				--exp.o = nil
				--exp.v = nil
				--fw.a = X(',', 
				--fw.v = arg(exp.f)
				--fw.f = arg(exp.f)
				fw.o = nil
				fw.f = nil
				fw.a = nil
				fw.v = fn(exp)

			else

				error('onbekende constructie ' .. e2s(exp))

				for k,v in subs(exp) do
					if k == 'f' or k == 'o' then
						fw[k] = v
					elseif fn(exp) == '[]u' then
						fw[k] = v
					elseif fn(exp) == '+' or fn(exp) == '_' then
						fw[k] = arg(v)
					else
						fw[k] = arg(v)
					end
					--fw[k].ref = v.ref
				end

			end
			
			stat.loc = exp.loc
			stat.code = exp.code

			--assert(exp.ref, e2s(stat)..' heeft geen referentie')
			--if exp.ref then
			--	al[exp.ref] = stat
			--end

			--print('NORMAAL', combineer(stat))
			fw.ref = exp.ref -- TODO nodig?
			mkstat(stat, ret)
		end

		--print('REG', combineer(exp), ret)
		al[moes(exp)] = ret
		return ret, gen2bron
	end

	con(exp)

	-- check
	for r in boompairs(exp) do
		if fn(r) == '_arg' then
			error"JAMMER DIT"
		end
	end

	return blokken
end

if test then
	require 'lisp'
	require 'ontleed'
	local E = ontleedexp

	local cfg = codegen(E[[
2 + als 2 > 1 dan
	2 * 3 + 4 - (2 + 3)
anders
	2 - 3
]])

	for blok in pairs(cfg.punten) do
		--print(blok)
	end

	local graaf2, blokken2 = codegen(E[[
;2 * 3 + 8 / 7 ^ 2 - (3 * 2 + 8 / 7)
(8*2/3*4) + (_fn(3, _arg(3) + 1))(2)
]])

	--control(E'_fn(0, _arg(0) + 1 · 3 ^ 2 + 8)')
	--control(E'_fn(0, _arg(0) ⇒ b · c + 3 / 7 ^ 3)')
end

