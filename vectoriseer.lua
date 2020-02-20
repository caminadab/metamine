require 'exp'

-- past types toe om operators te preoverloaden
function vectoriseer(asb, types)
	for exp in boompairsdfs(asb) do

		-- L_i → (_i)(L, i)
		if fn(exp) == '_' then
			local fntype = types[moes(arg0(exp))]
			local islijst = atoom(arg0(fntype)) == 'nat' or obj(fntype) == ','
			local isfunc = fn(fntype) == '→' and atoom(arg0(fntype)) ~= 'nat'

			if isfunc then
				exp.f = X'_f'
			elseif islijst then
				exp.f = X'_l'
			else
				print('Waarschuwing: vectortype van '..unlisp(exp)..' kon niet eenduidig worden bepaald')
			end
		end

		-- (F^i) → (^)(F, i)
		if fn(exp) == '^' then
			local basetype = types[moes(arg0(exp))]
			local isfunc = fn(basetype) == '→' or atoom(basetype) == 'functie'
			if isfunc then
				exp.f = X'^f'
			elseif atoom(basetype) == 'getal' or atoom(basetype) == 'int' then
				exp.f = X'^'
			else
				-- niets
			end
		end

		-- (+) → +v | +v1 | +m | +m1 | +f
		if fn(exp) == '+' then
			local atype = types[moes(arg0(exp))]
			local btype = types[moes(arg1(exp))]
			local isnumA = atoom(atype) == 'int' or atoom(atype) == 'getal'
			local isnumB = atoom(btype) == 'int' or atoom(btype) == 'getal'
			local isfuncA = fn(atype) == '→' or atoom(atype) == 'functie'
			local isfuncB = fn(atype) == '→' or atoom(atype) == 'functie'
			local islijstA = atoom(arg0(atype)) == 'nat' or obj(atype) == ','
			local islijstB = atoom(arg0(btype)) == 'nat' or obj(btype) == ','

			-- vector
			if islijstA and islijstB then exp.f = X'+v' 
			elseif islijstA and isnumB then exp.f = X'+v1' 
			elseif islijstB and isnumA then
				exp.f = X'+v1' 
				arg(exp)[1], arg(exp)[2] = arg(exp)[2], arg(exp)[1]

			-- functie
			elseif isfuncA and isfuncB then exp.f = X'+f'
			elseif isfuncA and isnumB then exp.f = X'+f1'
			elseif isfuncB and isnumA then
				exp.f = X'+f1' 
				arg(exp)[1], arg(exp)[2] = arg(exp)[2], arg(exp)[1]

			-- matrix TODO
			elseif isfuncA and isfuncB then exp.f = X'+m'
			elseif isfuncA and isnumB then exp.f = X'+m1'
			elseif isfuncB and isnumA then
				exp.f = X'+m1' 
				arg(exp)[1], arg(exp)[2] = arg(exp)[2], arg(exp)[1]
			end
		end

		if fn(exp) == '-' then
			local type = types[moes(arg(exp))]
			local isfunc = fn(type) == '→' or atoom(type) == 'functie'
			local islijst = atoom(arg0(type)) == 'nat' or obj(type) == ','

			if isfunc then
				exp.f = X'-f'
			elseif islijst then
				exp.f = X'-v'
			end
		end

		-- (+) → +v | +v1 | +m | +m1 | +f
		if fn(exp) == '·' then
			local atype = types[moes(arg0(exp))]
			local btype = types[moes(arg1(exp))]
			local isnumA = atoom(atype) == 'int' or atoom(atype) == 'getal'
			local isnumB = atoom(btype) == 'int' or atoom(btype) == 'getal'
			local isfuncA = fn(atype) == '→' or atoom(atype) == 'functie'
			local isfuncB = fn(atype) == '→' or atoom(atype) == 'functie'
			local islijstA = atoom(arg0(atype)) == 'nat' or obj(atype) == ','
			local islijstB = atoom(arg0(btype)) == 'nat' or obj(btype) == ','

			-- vector
			if islijstA and islijstB then exp.f = X'·v' 
			elseif islijstA and isnumB then exp.f = X'·v1' 
			elseif islijstB and isnumA then
				exp.f = X'·v1' 
				arg(exp)[1], arg(exp)[2] = arg(exp)[2], arg(exp)[1]

			-- functie
			elseif isfuncA and isfuncB then exp.f = X'·f'
			elseif isfuncA and isnumB then exp.f = X'·f1'
			elseif isfuncB and isnumA then
				exp.f = X'·f1' 
				arg(exp)[1], arg(exp)[2] = arg(exp)[2], arg(exp)[1]

			-- matrix TODO
			elseif isfuncA and isfuncB then exp.f = X'·m'
			elseif isfuncA and isnumB then exp.f = X'·m1'
			elseif isfuncB and isnumA then
				exp.f = X'·m1' 
				arg(exp)[1], arg(exp)[2] = arg(exp)[2], arg(exp)[1]
			end
		end
	end
	return asb
end

