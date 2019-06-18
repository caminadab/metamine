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
	y := arg 0
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

function controle(exp, maakvar)
	local graaf = maakgraaf()
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
	local blok = maakblok(X'start', {}, X'stop')
	graaf.start = blok
	graaf:punt(blok)

	local con

	local function arg(exp)
		local arg
		if isfn(exp) and fn(exp) == '[]' then
			arg = con(exp)
		elseif isfn(exp) then
			arg = con(exp)
		else
			arg = con(exp)
		end
		return arg
	end

	local al = {}

	function mkstat(stat, ret)
		stat.loc = exp.loc
		--stat.ref = ret.ref
		local val = stat[2]
		if verbozeIntermediair then
			print('  '..combineer(stat)..'  '..(val.ref and val.ref.v or ''))
		end
		--print(e2s(stat), val.ref)
		if not val.ref then
			--val.ref = X('~'..maakvar())
		end
		if val.ref then
			--error(val.ref)
			--al[ret.v] = val.ref
			al[val.ref.v] = stat[1]
				assert(isatoom(stat[1]))
			--print(e2s(stat), e2s(stat[1]))
			--print('REG:', val.ref.v, e2s(stat[1]))
			--al[ret.v] = assert(stat[2].ref, 'statement heeft geen referentiecode: '..e2s(stat))
		end
		if not val.ref and isfn(val) then
			--error('geen referentie voor '..e2s(val))
		end
		table.insert(blok.stats, stat)
		return ret
	end

	function con(exp,ret)
		--print('CON', combineer(exp))
		local fw = {fn=exp.fn}
		local ret = ret or X(maakvar())
		local stat = X(':=', ret, fw)

		if isatoom(exp) and atoom(exp):sub(1,1) == '~' then
			local stat = X(':=', ret, (assert(al[exp.v], 'niet geregistreerd: '..exp.v))) --assert(al[exp.v:sub(1,-2)], exp.v))
			--error('OK')
			stat.loc = exp.loc
			return mkstat(stat, ret)
		
		-- functie
		elseif fn(exp) == '_fn' then --isfn(exp) and fn(exp.fn) == '_fn' then
			assert(exp.ref)
			--al = {}
			local naam = X(maakfunc())
			local waarde = exp[1]
			local arg = exp[2]
			exp.v = naam.v
			exp.fn = nil
			exp[1] = nil
			exp[2] = nil
			local bfn = maakblok(naam, {}, X('ret', '9999999'))
			local b = blok
			blok = bfn
			al[ret.v] = stat[2]
			print('FN AL', ret.v, e2s(stat))
			stat[2].ref = assert(exp.ref)
			local res = con(waarde)
			blok.epiloog[1] = res
			graaf:punt(bfn)
			blok = b
			local stat = X(':=', ret, naam)
			stat.loc = exp.loc
			al[ret.v] = stat[2]
			--table.insert(blok.stats, stat)
			mkstat(stat, ret)

		-- alsdan!
		elseif fn(exp) == '=>' then
			local blok0 = blok
			local eals, edan, eanders = exp[1], exp[2], exp[3]
			
			-- procnamen
			local dan = X(maakproc())
			local anders = X(maakproc())
			local phi = X(maakproc())

			-- phi (eindcontinuatie)
			local bphi = maakblok(phi, {}, blok0.epiloog) -- krijgt zelfde eind
			graaf:link(blok, bphi)

			-- als
			blok = blok0
			local econd = con(eals)
			-- sprong
			blok.epiloog = X('ga', econd, dan, anders)

			-- dan
			local bdan = maakblok(dan, {}, X('ga', phi))
			graaf:link(blok, bdan)
			blok = bdan
			local rdan = con(edan)

			-- anders
			local banders = maakblok(anders, {}, X('ga', phi))
			graaf:link(blok, banders)
			blok = banders

			local randers = '???'
			if eanders then
				randers = con(eanders,rdan)
			end

			-- daadwerkelijke '=>'
			local stat = X(':=', ret, rdan)
			stat[2].ref = exp.ref
			al[ret.v] = rdan
			blok = bphi
			mkstat(stat, ret)

		elseif tonumber(exp) then
			stat[2] = X(tostring(exp))
			stat.loc = exp.loc
			mkstat(stat, ret)

		-- a := b
		elseif isatoom(exp) then
			stat[2] = exp
			stat.loc = exp.loc
			--al[exp] = stat[2]
			mkstat(stat, ret)

		-- normale statement (TODO sorteer)
		else
			if isfn(exp.fn) then
				fw.fn = arg(exp.fn)
			end
			if exp[1] and fn(exp[1]) == ',' then
				exp = exp[1]
			end
			for i,v in ipairs(exp) do
				fw[i] = arg(v)
			end
			stat.loc = exp.loc
			--stat[2].ref = exp.ref

			--assert(exp.ref, e2s(stat)..' heeft geen referentie')
			--if exp.ref then
			--	al[exp.ref] = stat
			--end

			--print('NORMAAL', combineer(stat))
			stat[2].ref = exp.ref
			mkstat(stat, ret)
		end

		--print('REG', combineer(exp), ret)
		al[moes(exp)] = ret
		return ret
	end
	con(exp)

	graaf.namen = {}
	for blok in pairs(graaf.punten) do
		graaf.namen[blok.naam.v] = blok
	end

	return graaf
end

if test then
	require 'lisp'
	require 'ontleed'
	local E = ontleedexp

	local cfg = controle(E[[
2 + als 2 > 1 dan
	2 * 3 + 4 - (2 + 3)
anders
	2 - 3
]])

	for blok in pairs(cfg.punten) do
		--print(blok)
	end

	local graaf2, blokken2 = controle(E[[
;2 * 3 + 8 / 7 ^ 2 - (3 * 2 + 8 / 7)
(8*2/3*4) + (_fn(3, _arg(3) + 1))(2)
]])

	--control(E'_fn(0, _arg(0) + 1 · 3 ^ 2 + 8)')
	--control(E'_fn(0, _arg(0) ⇒ b · c + 3 / 7 ^ 3)')
end

