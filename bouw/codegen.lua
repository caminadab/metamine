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
	'_f','_f2','_l','^f',
	'+v', '+v1', '·v', '·v1', '/v1',
	'+m', '+m1', '·m1'
)

-- exps worden gecachet (voor debugging)
function codegen(exp, exps)
	local exps = exps or {}
	local codeindex = {}
	local reused = {} -- exp → index
	local focus = 1
	local maakindex = maakindices(0)

	local bieb = bieb()

	function codegen(exp, ins)

		-- al gedaan
		if false and codeindex[exp] then
			local cindex = codeindex[exp]

			-- voeg sneaky toe
			local index
			if not reused[cindex] then
				index = maakindex()
				table.insert(ins, cindex+1, X('st', tostring(index)))
				reused[cindex] = index
				-- verschuif indices
				--[[
				for i=1,#codeindex do
					if codeindex[i] >= cindex then
						codeindex[i] = codeindex[i] + 1
					end
				end
				]]
			else
				index = reused[cindex]
			end
			--ins[#ins+1] = X('ld', tostring(index))

			return
		end

		-- causatie
		if fn(exp) == '⇒' then
			codegen(arg0(exp), ins)
			ins[#ins+1] = X'dan'

			-- met lege cache
			local ci = codeindex
			local r = reused
			codeindex = {}
			reused = {}
			codegen(arg1(exp), ins)
			codeindex = ci
			reused = r

			ins[#ins+1] = X'einddan'
			focus = focus - 1

		elseif fn(exp) == '_arg' then
			ins[#ins+1] = X('arg', atoom(arg(exp)))
			focus = focus + 1

		-- portable functies
		elseif binop[atoom(exp)] then
			ins[#ins+1] = X('fn', '999')
			ins[#ins+1] = X('arg', '999')
			ins[#ins+1] = X('0')
			ins[#ins+1] = X('_l')
			ins[#ins+1] = X('arg', '999')
			ins[#ins+1] = X('1')
			ins[#ins+1] = X('_l')
			ins[#ins+1] = exp
			ins[#ins+1] = X('eind')
			focus = focus + 1

		elseif unop[atoom(exp)] then
			ins[#ins+1] = X('fn', '999')
			ins[#ins+1] = X('arg', '999')
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
			ins[#ins+1] = X('fn', atoom(arg0(exp)))

			-- met lege cache
			local ci = codeindex
			local r = reused
			codeindex = {}
			reused = {}
			codegen(arg1(exp), ins)
			codeindex = ci
			reused = r

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

		if false and exps[exp] then
			index = maakindex()
			ins[#ins+1] = X('st', tostring(index))
		end
		
		return ins, reused
	end

	local ins = {o='[]'}
	return codegen(exp, ins)
end
