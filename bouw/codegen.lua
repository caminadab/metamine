require 'exp'
require 'util'
require 'graaf'
require 'symbool'
require 'combineer'

require 'bouw.blok'

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
local binop  = set("+","·","/","^"," ","∨","∧","×","..","→","∘","_","‖","⇒",">","≥","=","≠","≈","≤","<",":=","+=","|:=", "∪","∩",":","∈")
local unop   = set("-","#","¬","Σ","|","%","√","!")

function codegen(exp, maakvar)
	local maakvar = maakvar or maakvars()
	local stats = {o=X","}
	local exp2naam = {}
	local moes2naam = {}
	local recycled = 0
	local totaal = 0

	for sub in boompairsdfs(exp) do
		-- bestaat al?
		if moes2naam[e2s(sub)] then
			recycled = recycled + 1
			totaal = totaal + 1
			exp2naam[sub] = moes2naam[e2s(sub)]
		else
			totaal = totaal + 1
			local gen = maakvar()

			local val
			if isfn(sub) then
				val = {f=sub.f}
				val.a = X((assert(exp2naam[sub.a], e2s(sub))))
			end
			if isobj(sub) then
				val = {o=sub.o}
				for k, sub in subs(sub) do
					val[k] = X((assert(exp2naam[sub], e2s(sub))))
				end
			end
			if isatoom(sub) then
				val = sub
			end
			local stat = X(":=", gen, val)
			exp2naam[sub] = gen
			moes2naam[e2s(sub)] = gen
			stats[#stats+1] = stat
		end
	end
	print(math.floor(recycled/totaal*100)..'% gerecycled')

	-- contract stats
	if false then
	for i=#stats-1,2,-1 do
		local x = stats[i+0]
		local y = stats[i+1]

		if isobj(arg1(x)) and isfn(arg1(y)) and isatoom(arg(arg1(y))) then
			arg1(y).a = x.a[2]
			table.remove(stats, i)
		end

		if false and isatoom(arg1(x)) and isfn(arg1(y)) then
			y.a[2].a = x.a[2]
			table.remove(stats, i)
		end

	end

	end

	return stats
end

-- maakt de app
function codegen2(exp, maakvar)
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

	local function arg(exp)
		if tonumber(exp.v) then
			return exp
		else
			return con(exp)
		end
	end

	function mkstat(stat, ret)
		stat.loc = exp.loc

		local val = stat.a[2]
		table.insert(blok.stats, stat)
		return ret
	end

	function con(exp,ret)
		local fw = {}
		local ret = ret or X(maakvar())
		local stat = X(':=', ret, fw)

		-- functie
		if fn(exp) == '_fn' then
			local naam = X(maakfunc())
			local waarde = exp.a
			local arg = X('_arg', waarde)
			local keys = {}
			for k in pairs(exp) do keys[k] = true end
			for k in pairs(keys) do exp[k] = nil end
			exp.v = naam.v
			local bfn = maakblok(naam, {}, X('ret', '?'))
			local b = blok
			blok = bfn

			local res = con(waarde)
			blok.epiloog.a[1] = res

			blokken[bfn.naam.v] = bfn

			blok = b
			local stat = X(':=', ret, naam)
			stat.loc = exp.loc
			stat.code = exp.code

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
			stat.a[2].ref = exp.ref
			mkstat(stat, ret)

		-- normale statement (TODO sorteer)
		else
			local fw = {f=exp.f}
			local ret = ret or X(maakvar())
			local stat = X(':=', ret, fw)
			if not exp.f and not exp.o then error(e2s(exp)) end

			if binop[fn(exp)] then
				fw.f = exp.f
				fw.a = X(',', arg(exp.a[1]), arg(exp.a[2]))

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
				end

			end
			
			mkstat(stat, ret)
		end

		return ret
	end

	con(exp)

	return blokken
end

