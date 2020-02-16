require 'exp'
require 'util'
require 'graaf'
require 'symbool'
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

local unop   = set('-','#','¬','Σ','|','√','!','%')
local binop  = set(
	'+','·','/','^','mod',
	'∨','∧','×','..','→','∘','_','‖','⇒','>','≥','=','≠','≈','≤','<',':=','+=','|:=',
	'∪','∩',':','∈',
	'_f','_f2','_l','^f','^l'
)

function codegen2(exp, maakvar)
	local maakvar = maakvar or maakvars()
	local stats = X(",")
	local klaar = {}

	for sub in boompairsdfs(exp) do
		-- bestaat al?
		if not klaar[sub] then
			local gen = maakvar()

			local val
			if isfn(sub) then
				val = {f=sub.f}
				val.a = X((assert(klaar[sub.a], e2s(sub))))
			end
			if isobj(sub) then
				val = {o=sub.o}
				for k, sub in subs(sub) do
					val[k] = X((assert(klaar[sub], e2s(sub))))
				end
			end
			if isatoom(sub) then
				val = sub
			end
			local stat = X(":=", gen, val)
			klaar[sub] = gen
			stats[#stats+1] = stat
		end
	end

	-- contract stats
	if false then
		for i=#stats-1,2,-1 do
			local x = stats[i+0]
			local y = stats[i+1]

			local v, w = arg1(x), arg1(y)

			if isobj(arg1(x))
					and obj(v) == ','
					and isfn(w)
					and isatoom(arg(w)) then
				v.a = w
				--table.remove(stats, i)
			end

			if false and isatoom(arg1(x)) and isfn(arg1(y)) then
				y.a[2].a = x.a[2]
				table.remove(stats, i)
			end

		end
	end

	return stats
end


function constantgen(exp, ins)
	if isatoom(exp) then
		ins[#ins+1] = X('put', exp)
	
	elseif isobj(exp) then
		for i,sub in ipairs(exp) do
			ins[#ins+1] = X('put', exp)
		end

		if obj(exp) ~= ',' then
			ins[#ins+1] = X(obj(exp), tostring(#exp))
		end

	end
end

local klaar = {}
local stack = {}
local appindex = 1

local bieb = bieb()

function codegen(exp, ins)
	local ins = ins or {o='[]'}
	if klaar[exp] then
		ins[#ins+1] = X('1')
		return
	end
	klaar[exp] = true
	stack[#stack+1] = exp

	if fn(exp) == 'fn.merge' then
		local len = #arg(exp)
		ins[#ins+1] = X('rep', tostring(len))
		for i,sub in ipairs(arg(exp)) do
			codegen(sub, ins)
			if i ~= #arg(exp) then
				ins[#ins+1] = X('wissel', tostring(-i))
			end
		end

	-- causatie
	elseif fn(exp) == '⇒' then
		codegen(arg0(exp), ins)
		ins[#ins+1] = X'dan'
		codegen(arg1(exp), ins)
		ins[#ins+1] = X'einddan'

	elseif fn(exp) == 'fn.constant' then
		constantgen(arg(exp), ins)

	elseif fn(exp) == '_arg' then
		ins[#ins+1] = X('arg', atoom(arg(exp)))
	
	elseif bieb[atoom(exp)] then
		ins[#ins+1] = exp

	elseif false and fn(exp) == '∘' then
		local var = tostring(1000 + appindex)
		appindex = appindex + 1
		ins[#ins+1] = X('fn', var)
		ins[#ins+1] = X('arg', var)
		for i, sub in ipairs(arg(exp)) do
			codegen(sub, ins)
		end
		ins[#ins+1] = X'eind'

	elseif binop[fn(exp)] then
		codegen(arg0(exp), ins)
		codegen(arg1(exp), ins)
		ins[#ins+1] = X(fn(exp))

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
		end

	elseif isatoom(exp) then
		ins[#ins+1] = exp
	
	else
		ins[#ins+1] = exp
	end
	
	return ins
end
