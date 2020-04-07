require 'exp'
require 'util'
require 'graaf'
require 'symbool'
require 'bieb'
require 'combineer'

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

local unop   = set('-','#','¬','Σ','|','√','!','%','-v','-m')
local binop  = set(
	'+','·','/','^',
	'∨','∧','×','..','→','∘','_','‖','⇒','>','≥','=','≠','≈','≤','<',':=','+=','|:=',
	'∪','∩',':','∈','\\',
	'_f','_f2','_t','_l','^f',
	'+v', '+v1', '·v', '·v1', '/v1',
	'+m', '+m1', '·m1', '·mv', '·m'
)

-- exps worden gecachet (voor debugging)
function codegen(exp, moes2naam)
	local moes2naam = moes2naam or {}
	local codeindex = {}
	local reused = {} -- exp → index
	local focus = 1
	local maakindex = maakindices(0)
	local maakcacheindex = maakindices(0)
	local argindex = {} -- num → index
	local maakargindex = maakindices(0)

	local bieb = bieb()

	-- zoek dubbele
	local exps = {}
	local dubbel = {} -- exp → cacheindex
	local iscached = {} -- exp → bit


	local function rec(exp)
		if exps[exp] then
			if not isatoom(exp) then
				dubbel[exp] = true
				return
			end
		end
		exps[exp] = true
		for k,sub in subs(exp) do
			rec(sub)
		end
	end
	rec(exp)

	local function codegen(exp, ins)

		if iscached[exp] then
			ins[#ins+1] = X('ld', tostring(iscached[exp]))
			return
		end

		-- causatie
		if fn(exp) == '⇒' then
			codegen(arg0(exp), ins)
			ins[#ins+1] = X'dan'

			-- met lege cache
			local ic = iscached
			local d = dubbel
			iscached = {}
			dubbel = {}
			codegen(arg1(exp), ins)
			iscached = ic
			dubbel = d

			ins[#ins+1] = X'einddan'
			focus = focus - 1

		elseif fn(exp) == '_arg' then
			local num = atoom(arg(exp))
			if not argindex[num] then
				argindex[num] = tostring(maakargindex())
				--print('reg arg', argindex[num], num)
			end
			ins[#ins+1] = X('arg', argindex[num])
			focus = focus + 1

		-- portable functies
		elseif binop[atoom(exp)] then
			local index = tostring(maakargindex())
			ins[#ins+1] = X('fn', index)
			ins[#ins+1] = X('arg', index)
			ins[#ins+1] = X('0')
			ins[#ins+1] = X('_l')
			ins[#ins+1] = X('arg', index)
			ins[#ins+1] = X('1')
			ins[#ins+1] = X('_l')
			ins[#ins+1] = exp
			ins[#ins+1] = X('eind')
			focus = focus + 1

		elseif unop[atoom(exp)] then
			local index = tostring(maakargindex())
			ins[#ins+1] = X('fn', index)
			ins[#ins+1] = X('arg', index)
			ins[#ins+1] = exp
			ins[#ins+1] = X('eind')
			focus = focus + 1

		elseif bieb[atoom(exp)] then
			ins[#ins+1] = exp
			focus = focus + 1

		elseif binop[fn(exp)] then
			codegen(arg0(exp), ins)
			codegen(arg1(exp), ins)
			ins[#ins+1] = X(fn(exp))
			focus = focus - 1

		elseif unop[fn(exp)] then
			codegen(arg(exp), ins)
			ins[#ins+1] = X(fn(exp))

		-- _fn(1 +(1 _arg(1))) -> fn
		-- functie
		elseif fn(exp) == '_fn' then
			local num = atoom(arg0(exp))
			if not argindex[num] then
				argindex[num] = tostring(maakargindex())
				--print('reg fn', argindex[num], num)
			end
			ins[#ins+1] = X('fn', argindex[num])

			-- met lege cache
			local ic = iscached
			local d = dubbel
			codeindex = {}
			reused = {}
			dubbel = {}
			codegen(arg1(exp), ins)
			iscached = ic
			dubbel = d

			ins[#ins+1] = X'eind'
		
		elseif fn(exp) == 'rep' then
			ins[#ins+1] = exp
			focus = focus + 1

		elseif isobj(exp) then
			for i=1,#exp do
				local sub = exp[i]
				codegen(sub, ins)
			end
			if     obj(exp) == ',' then
				ins[#ins+1] = X('tupel', tostring(#exp))
			elseif obj(exp) == '[]' then
				ins[#ins+1] = X('lijst', tostring(#exp))
			elseif obj(exp) == '{}' then
				ins[#ins+1] = X('set', tostring(#exp))
			elseif obj(exp) == '"' then
				ins[#ins+1] = X('string', tostring(#exp))
			end

		elseif isatoom(exp) then
			ins[#ins+1] = exp
			focus = focus + 1
		
		else
			ins[#ins+1] = exp
			focus = focus + 1

		end

		codeindex[exp] = #ins

		if not isatoom(exp) and dubbel[exp] or moes2naam[moes(exp)] then
			iscached[exp] = maakcacheindex()
			ins[#ins+1] = X('st', tostring(iscached[exp]))
		end

		return ins, iscached
	end

	local ins = {o='[]'}
	return codegen(exp, ins)
end
