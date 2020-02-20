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

local unop   = set('-','#','¬','Σ','|','√','!','%','-v', '-m')
local binop  = set(
	'+','·','/','^','mod',
	'∨','∧','×','..','→','∘','_','‖','⇒','>','≥','=','≠','≈','≤','<',':=','+=','|:=',
	'∪','∩',':','∈','|',
	'_f','_f2','_l','^f','^l',
	'+v', '+v1', '·v', '·v1',
	'+m', '+m1', '·m1'
)

local klaar = {} -- exp → stackdepth
local klaardiepte = {}
local diepte = {} -- exp → waarzo
local focus = 1

local bieb = bieb()

function codegen(exp, ins)
	local ins = ins or {o='[]'}
	local focus = 1

	if false and klaar[exp] then
		local tussen = klaar[exp]
		local diepte = klaardiepte[exp]

		-- voeg sneaky toe
		table.insert(ins, tussen+1, X'dup')
		ins[#ins+1] = X('kp', tostring(diepte))

		return
	end

	-- causatie
	if fn(exp) == '⇒' then
		codegen(arg0(exp), ins)
		ins[#ins+1] = X'dan'
		codegen(arg1(exp), ins)
		ins[#ins+1] = X'einddan'
		focus = focus - 1

	elseif fn(exp) == '_arg' then
		ins[#ins+1] = X('arg', atoom(arg(exp)))
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
		codegen(arg1(exp), ins)
		ins[#ins+1] = X'eind'
	
	elseif fn(exp) == 'rep' then
		ins[#ins+1] = exp
		focus = focus + 1

	elseif isobj(exp) then
		for i,sub in ipairs(exp) do
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

	klaar[exp] = #ins
	klaardiepte[exp] = focus
	
	return ins
end
