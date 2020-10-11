	require 'exp'
	require 'util'
	require 'graph'
	require 'symbol'
	require 'lib'
	require 'deparse'
	require 'unicode'

	-- diepte bepalen
	local function peil(waarde)
		-- bepaal diepte
		local diepte = {}

		for exp in treepairsdfs(waarde) do
			-- bladwaarden krijgen 1
			if isatom(exp) then
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

	unop   = set('-','#','¬','Σ','⋁','⋀','|','√','!','%','-v','-m','index0','igen','²','³')
	binop  = set(
		'+','·','/','^','^l',
		'∨','∧','×','×t','..','→','∘','_','‖','>','≥','=','≠','≈','≤','<',':=','+=','|:=',
		'=g','≠g',
		'∪','∩',':','∈','\\', '||=',
		'call','callm','call1','_t','index','^f', '^l','igeni',
		'+v', '+v1', '·v', '·v1', '/v1',
		'+f', '+f1', '·f', '·f1', '/f', '/f1',
		'+m', '+m1', '·m1', '·mv', '·m',
		'>f', '<f', '≤f', '≥f', '=f',
		'>f1', '<f1', '≤f1', '≥f1', '=f1'
	)
	triop  = set('call2', 'kies', '⇒')

-- exps worden gecachet (voor debugging)
function codegen(exp, hash2name)
	local hash2name = hash2name or {}
	local codeindex = {}
	local reused = {} -- exp → index
	local focus = 1
	local maakindex = maakindices(0)
	local maakcacheindex = maakindices(0)
	local argindex = {} -- num → index
	local maakargindex = maakindices(0)

	local lib = lib()

	-- zoek dubbele
	local exps = {}
	local dubbel = {} -- exp → cacheindex
	local cachemap = {} -- exp → int


	local function rec(exp)
		if exps[hash(exp)] then
			if not isatom(exp) then
				dubbel[hash(exp)] = true
				--print('DUBBEL', deparse(exp))
				return
			end
		end
		exps[hash(exp)] = true
		for k,sub in subs(exp) do
			rec(sub)
		end
	end
	rec(exp)

	local function codegen(exp, ins, callarg)
		if cachemap[hash(exp)] then
			ins[#ins+1] = X('ld', tostring(cachemap[hash(exp)]))
			return
		end

		-- causatie
		if fn(exp) == '⇒' then
			codegen(arg0(exp), ins, callarg)
			ins[#ins+1] = X'dan'

			-- met lege cache
			local ic = cachemap
			local d = dubbel
			cachemap = {}
			dubbel = {}

			codegen(arg1(exp), ins, callarg)

			ins[#ins+1] = X'anders'
			if arg2(exp) then
				codegen(arg2(exp), ins, callarg)
			else
				codegen(X'niets', ins, callarg)
			end


			cachemap = ic
			dubbel = d

			ins[#ins+1] = X'einddan'
			focus = focus - 1

		elseif false and fn(exp) == '_arg' and exp.a.v == callarg then
			--ins[#ins+1] = 
			--error'OK'
			focus = focus + 1

    elseif fn(exp) == '_arg' then
			local num = atom(arg(exp))
			if not argindex[num] then
				argindex[num] = tostring(maakargindex())
				--print('reg arg', argindex[num], num)
			end
			ins[#ins+1] = X('arg', num) --argindex[num])
			focus = focus + 1

		elseif false and fn(exp) == '_arg0' and callarg == atom(arg(exp)) then
		elseif false and fn(exp) == '_arg1' and callarg == atom(arg(exp)) then
			-- klaar

		elseif fn(exp) == '_arg0' then
			local num = atom(arg(exp))
			ins[#ins+1] = X('arg0', num) --argindex[num])
			focus = focus + 1
		elseif fn(exp) == '_arg1' then
			local num = atom(arg(exp))
			ins[#ins+1] = X('arg1', num) --argindex[num])
			focus = focus + 1
		elseif fn(exp) == '_arg2' then
			local num = atom(arg(exp))
			ins[#ins+1] = X('arg2', num) --argindex[num])
			focus = focus + 1
		elseif fn(exp) == '_arg3' then
			local num = atom(arg(exp))
			ins[#ins+1] = X('arg3', num) --argindex[num])
			focus = focus + 1

		elseif atom(exp) == 'id' then
			-- ok

		elseif fn(exp) == 'ifilter' then
			local gen = arg0(exp)
			local pred = arg1(exp)
			local predindex = atom(arg0(pred))

			codegen(gen, ins, callarg)
			codegen(arg1(pred), ins, predindex)
			ins[#ins+1] = X'ifilter'

		elseif fn(exp) == 'lus' then
			local start = arg0(exp)
			local gen = arg1(exp)
			local col = arg2(exp)

			local colarg = fn(col) == '_fn' and atom(arg0(col))
			--local col    = fn(col) == '_fn' and arg1(col) or col
			--callarg[atom(arg0(col))] = 
				

			--error(deparse(col))

			ins[#ins+1] = X'lus'
			codegen(start, ins, callarg)
			codegen(gen, ins, callarg)
			codegen(col, ins, 2)
			ins[#ins+1] = X'eindlus'

		elseif fn(exp) == 'lusbreak' then
			local start = arg0(exp)
			local gen = arg1(exp)
			local col = arg2(exp)
			local breakk = arg3(exp)
			error'OK'

			local colarg = fn(col) == '_fn' and atom(arg0(col))
			--local col    = fn(col) == '_fn' and arg1(col) or col
			--callarg[atom(arg0(col))] = 
				

			--error(deparse(col))

			ins[#ins+1] = X'lus'
			codegen(start, ins, callarg)
			codegen(breakk, ins, callarg)
			codegen(gen, ins, callarg)
			codegen(col, ins, 2)
			ins[#ins+1] = X'eindlus'

		-- optimisatie
		-- llus: (num) -> (nlijst)
		elseif fn(exp) == 'llus' then
			local num = arg0(exp)
			local func = arg1(exp)
			local iscomplex = fn(func) == '_fn'
			local argindex, body = atom(arg0(func)), arg1(func)
			local callarg = argindex

			assert(num, deparse(exp))

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
			local argindex, body = atom(arg0(func)), arg1(func)
			local callarg = argindex

			assert(num, deparse(exp))

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

		elseif lib[atom(exp)] then
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
			local num = atom(arg0(exp))
			if not argindex[num] then
				argindex[num] = tostring(maakargindex())
				--print('reg fn', argindex[num], num)
			end
			ins[#ins+1] = X('fn', num)--argindex[num])

			-- met lege cache
			local ic = cachemap
			local d = dubbel
			codeindex = {}
			reused = {}
			--dubbel = {}
			codegen(arg1(exp), ins, callarg)
			cachemap = ic
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

		elseif isatom(exp) then
			ins[#ins+1] = exp
			focus = focus + 1

		elseif fn(exp) == 'icode' then
			--for i= 1, 
			local jns = {}
			codegen(arg(exp), jns, nil)
			for i=1,#jns do
				local m = hash(jns[i])
				for i, char in utf8pairs(m) do
					ins[#ins+1] = X(tostring(char))
				end
				ins[#ins+1] = X('string', tostring(#m))
			end
			ins[#ins+1] = X('lijst', tostring(#jns))

		else
			error('hoe gaan we dit doen? '..deparse(exp))
			ins[#ins+1] = exp
			focus = focus + 1

		end

		codeindex[exp] = #ins

		if not isatom(exp) and dubbel[hash(exp)] or hash2name[hash(exp)] then
			cachemap[hash(exp)] = maakcacheindex()
			ins[#ins+1] = X('st', tostring(cachemap[hash(exp)]))
		end

		return ins, cachemap
	end

	local ins = {o='[]'}
	return codegen(exp, ins, {})
end
