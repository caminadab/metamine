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

unop   = set('-','#','¬','Σ','⋁','⋀','|','√','!','%','-v','-m','index0','igen')
binop  = set(
	'+','·','/','^','^l',
	'∨','∧','×','×t','..','→','∘','_','‖','>','≥','=','≠','≈','≤','<',':=','+=','|:=',
	'=g','≠g',
	'∪','∩',':','∈','\\', '||=',
	'call','call1','_t','index','^f', '^l','igeni',
	'+v', '+v1', '·v', '·v1', '/v1',
	'+f', '+f1', '·f', '·f1',
	'+m', '+m1', '·m1', '·mv', '·m'
)
triop  = set('call2', 'kies', '⇒')

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

	local function codegen(exp, ins, callarg)
		if iscached[exp] then
			ins[#ins+1] = X('ld', tostring(iscached[exp]))
			return
		end

		-- causatie
		if fn(exp) == '⇒' then
			codegen(arg0(exp), ins, callarg)
			ins[#ins+1] = X'dan'

			-- met lege cache
			local ic = iscached
			local d = dubbel
			iscached = {}
			dubbel = {}

			codegen(arg1(exp), ins, callarg)

			ins[#ins+1] = X'anders'
			if arg2(exp) then
				codegen(arg2(exp), ins, callarg)
			else
				codegen(X'niets', ins, callarg)
			end


			iscached = ic
			dubbel = d

			ins[#ins+1] = X'einddan'
			focus = focus - 1

		elseif false and fn(exp) == '_arg' and exp.a.v == callarg then
			--ins[#ins+1] = 
			--error'OK'
			focus = focus + 1

    elseif fn(exp) == '_arg' then
			local num = atoom(arg(exp))
			if not argindex[num] then
				argindex[num] = tostring(maakargindex())
				--print('reg arg', argindex[num], num)
			end
			ins[#ins+1] = X('arg', num) --argindex[num])
			focus = focus + 1

		elseif false and fn(exp) == '_arg0' and callarg == atoom(arg(exp)) then
		elseif false and fn(exp) == '_arg1' and callarg == atoom(arg(exp)) then
			-- klaar

		elseif fn(exp) == '_arg0' then
			local num = atoom(arg(exp))
			ins[#ins+1] = X('arg0', num) --argindex[num])
			focus = focus + 1
		elseif fn(exp) == '_arg1' then
			local num = atoom(arg(exp))
			ins[#ins+1] = X('arg1', num) --argindex[num])
			focus = focus + 1
		elseif fn(exp) == '_arg2' then
			local num = atoom(arg(exp))
			ins[#ins+1] = X('arg2', num) --argindex[num])
			focus = focus + 1
		elseif fn(exp) == '_arg3' then
			local num = atoom(arg(exp))
			ins[#ins+1] = X('arg3', num) --argindex[num])
			focus = focus + 1

		elseif atoom(exp) == 'id' then
			-- ok

		elseif fn(exp) == 'ifilter' then
			local gen = arg0(exp)
			local pred = arg1(exp)
			local predindex = atoom(arg0(pred))

			codegen(gen, ins, callarg)
			codegen(arg1(pred), ins, predindex)
			ins[#ins+1] = X'ifilter'

		elseif fn(exp) == 'lus' then
			local start = arg0(exp)
			local gen = arg1(exp)
			local col = arg2(exp)

			local colarg = fn(col) == '_fn' and atoom(arg0(col))
			--local col    = fn(col) == '_fn' and arg1(col) or col
			--callarg[atoom(arg0(col))] = 
				

			--error(combineer(col))

			ins[#ins+1] = X'lus'
			codegen(start, ins, callarg)
			codegen(gen, ins, callarg)
			codegen(col, ins, 2)
			ins[#ins+1] = X'eindlus'

		-- optimisatie
		-- llus: (num) -> (nlijst)
		elseif fn(exp) == 'llus' then
			local num = arg0(exp)
			local func = arg1(exp)
			local iscomplex = fn(func) == '_fn'
			local argindex, body = atoom(arg0(func)), arg1(func)
			local callarg = argindex

			assert(num, combineer(exp))

			codegen(num, ins, callarg)
			ins[#ins+1] = X'llus'
			if iscomplex then
				codegen(body, ins, callarg)
			else
				ins[#ins+1] = func
				ins[#ins+1] = X'_fr'
			end
			ins[#ins+1] = X'eindllus'
			focus = focus + 0

		-- slus: (num) -> (res)
		elseif fn(exp) == 'slus' then
			local num = arg(exp)
			local iscomplex = fn(func) == '_fn'
			local argindex, body = atoom(arg0(func)), arg1(func)
			local callarg = argindex

			assert(num, combineer(exp))

			codegen(num, ins, callarg)
			ins[#ins+1] = X'slus'
			if true then
			--
			elseif iscomplex then
				codegen(body, ins, callarg)
			else
				ins[#ins+1] = func
				ins[#ins+1] = X'_fr'
			end
			ins[#ins+1] = X'eindslus'
			focus = focus + 0

		elseif bieb[atoom(exp)] then
			ins[#ins+1] = exp
			focus = focus + 1

		elseif binop[fn(exp)] then
			codegen(arg0(exp), ins, callarg)
			codegen(arg1(exp), ins, callarg)
			ins[#ins+1] = X(fn(exp))
			focus = focus - 1

		elseif triop[fn(exp)] then
			codegen(arg0(exp), ins, callarg)
			codegen(arg1(exp), ins, callarg)
			codegen(arg2(exp), ins, callarg)
			ins[#ins+1] = X(fn(exp))
			focus = focus - 2

		elseif fn(exp) == 'call3' then
			codegen(arg0(exp), ins, callarg)
			codegen(arg1(exp), ins, callarg)
			codegen(arg2(exp), ins, callarg)
			codegen(arg3(exp), ins, callarg)
			ins[#ins+1] = X(fn(exp))
			focus = focus - 3

		elseif fn(exp) == 'call4' then
			codegen(arg0(exp), ins, callarg)
			codegen(arg1(exp), ins, callarg)
			codegen(arg2(exp), ins, callarg)
			codegen(arg3(exp), ins, callarg)
			codegen(arg4(exp), ins, callarg)
			ins[#ins+1] = X(fn(exp))
			focus = focus - 4

		elseif unop[fn(exp)] then
			codegen(arg(exp), ins, callarg)
			ins[#ins+1] = X(fn(exp))

		elseif fn(exp) == '_fn' and callarg == 2 then
			ins[#ins+1] = X('stargs', arg0(exp))
			codegen(arg1(exp), ins, 2)

		-- _fn(1 +(1 _arg(1))) -> fn
		-- functie
		elseif fn(exp) == '_fn' then
			local num = atoom(arg0(exp))
			if not argindex[num] then
				argindex[num] = tostring(maakargindex())
				--print('reg fn', argindex[num], num)
			end
			ins[#ins+1] = X('fn', num)--argindex[num])

			-- met lege cache
			local ic = iscached
			local d = dubbel
			codeindex = {}
			reused = {}
			dubbel = {}
			codegen(arg1(exp), ins, callarg)
			iscached = ic
			dubbel = d

			ins[#ins+1] = X'eind'
		
		elseif fn(exp) == 'rep' then
			ins[#ins+1] = exp
			focus = focus + 1

		elseif isobj(exp) then
			for i=1,#exp do
				local sub = exp[i]
				codegen(sub, ins, callarg)
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
	return codegen(exp, ins, {})
end
