require 'exp'

-- past types toe om operators te preoverloaden
function vectoriseer(asb, types)
	for exp in boompairsdfs(asb) do

		-- L_i → (_i)(L, i)
		if fn(exp) == '_' then
			local fntype = types[moes(arg0(exp))]
			local islijst = atoom(arg0(fntype)) == 'nat' or obj(fntype) == ','
			local istekst = fn(fntype) == '→' and atoom(arg0(fntype)) == 'nat' and atoom(arg1(fntype)) == 'letter'
			local isfunc = fn(fntype) == '→' and atoom(arg0(fntype)) ~= 'nat'

			if isfunc then
				exp.f = X'_f'
			elseif istekst then
				exp.f = X'_t'
			elseif islijst then
				exp.f = X'_l'
			else
				--print('Waarschuwing: vectortype van '..unlisp(exp)..' kon niet eenduidig worden bepaald')
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

		-- TODO set -

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
			local ismatA = atoom(arg0(atype)) == 'nat' and atoom(arg0(arg1(atype))) == 'nat'
			local ismatB = atoom(arg0(btype)) == 'nat' and atoom(arg0(arg1(btype))) == 'nat'

			-- vector
			if islijstA and islijstB then exp.f = X'+v' 
			elseif islijstA and isnumB then exp.f = X'+v1' 
			elseif islijstB and isnumA then
				exp.f = X'+v1' 
				arg(exp)[1], arg(exp)[2] = arg(exp)[2], arg(exp)[1]

			-- functie
			elseif isfuncA and isfuncB then exp.f = X'+v'
			elseif isfuncA and isnumB then exp.f = X'+v1'
			elseif isfuncB and isnumA then
				exp.f = X'+v1' 
				arg(exp)[1], arg(exp)[2] = arg(exp)[2], arg(exp)[1]

			-- matrix
			elseif ismatA and ismatB then exp.f = X'+m'
			elseif ismatA and isnumB then exp.f = X'+m1'
			elseif isnumA and ismatB then
				exp.f = X'+m1' 
				arg(exp)[1], arg(exp)[2] = arg(exp)[2], arg(exp)[1]
			end
		end

		if fn(exp) == '-' then
			local type = types[moes(arg(exp))]
			local isnum = atoom(type) == 'int' or atoom(type) == 'getal'
			local isfunc = fn(type) == '→' or atoom(type) == 'functie'
			local islijst = atoom(arg0(type)) == 'nat' or obj(type) == ','
			local ismat = atoom(arg0(type)) == 'nat' and atoom(arg0(arg1(type))) == 'nat'

			--local type = types[moes(arg(exp))]
			--local isfunc = fn(type) == '→' or atoom(type) == 'functie'
			--local islijst = atoom(arg0(type)) == 'nat' or obj(type) == ','
			--local ismat = atoom(arg0(type)) == 'nat' and atoom(arg0(arg1(type))) == 'nat'

			if islijst then
				exp.f = X'-v'
			elseif isfunc then
				exp.f = X'-f'
			else
				exp.f = X'-'
			end
		end

		-- (/) → +/ | +/1 | /m1 | /f
		if fn(exp) == '/' then
			local atype = types[moes(arg0(exp))]
			local btype = types[moes(arg1(exp))]
			local isnumA = atoom(atype) == 'int' or atoom(atype) == 'getal'
			local isnumB = atoom(btype) == 'int' or atoom(btype) == 'getal'
			local isfuncA = fn(atype) == '→' or atoom(atype) == 'functie'
			local isfuncB = fn(atype) == '→' or atoom(atype) == 'functie'
			local islijstA = atoom(arg0(atype)) == 'nat' or obj(atype) == ','
			local islijstB = atoom(arg0(btype)) == 'nat' or obj(btype) == ','

			-- matrix TODO
			if isfuncA and isfuncB then exp.f = X'/m'
			elseif isfuncA and isnumB then exp.f = X'/m1'
			elseif isfuncB and isnumA then
				exp.f = X'/m1' 
				arg(exp)[1], arg(exp)[2] = arg(exp)[2], arg(exp)[1]

			-- vector
			elseif islijstA and islijstB then exp.f = X'/v' 
			elseif islijstA and isnumB then exp.f = X'/v1' 
			elseif islijstB and isnumA then
				exp.f = X'/v1' 
				arg(exp)[1], arg(exp)[2] = arg(exp)[2], arg(exp)[1]

			-- functie
			elseif isfuncA and isfuncB then exp.f = X'/f'
			elseif isfuncA and isnumB then exp.f = X'/f1'
			elseif isfuncB and isnumA then
				exp.f = X'/f1' 
				arg(exp)[1], arg(exp)[2] = arg(exp)[2], arg(exp)[1]

			end
		end

		-- (·) → ·v | ·v1 | ·m | ·mv | ·m1 | ·f
		if fn(exp) == '·' then
			local atype = types[moes(arg0(exp))]
			local btype = types[moes(arg1(exp))]
			local isnumA = atoom(atype) == 'int' or atoom(atype) == 'getal'
			local isnumB = atoom(btype) == 'int' or atoom(btype) == 'getal'
			local isfuncA = fn(atype) == '→' or atoom(atype) == 'functie'
			local isfuncB = fn(atype) == '→' or atoom(atype) == 'functie'
			local islijstA = atoom(arg0(atype)) == 'nat' or obj(atype) == ','
			local islijstB = atoom(arg0(btype)) == 'nat' or obj(btype) == ','
			local ismatA = atoom(arg0(atype)) == 'nat' and atoom(arg0(arg1(atype))) == 'nat'
			local ismatB = atoom(arg0(btype)) == 'nat' and atoom(arg0(arg1(btype))) == 'nat'
			--print(combineer(atype), combineer(btype))

			-- matrix
			if ismatA and ismatB then exp.f = X'·m' -- matrix multiplication!!
			elseif ismatA and islijstB then exp.f = X'·mv'
			elseif islijstA and ismatB then
				exp.f = X'·mv' 
				arg(exp)[1], arg(exp)[2] = arg(exp)[2], arg(exp)[1]
			elseif ismatA and isnumB then exp.f = X'·m1'
			elseif isnumA and ismatB then
				exp.f = X'·m1' 
				arg(exp)[1], arg(exp)[2] = arg(exp)[2], arg(exp)[1]

			-- vector
			elseif islijstA and islijstB then exp.f = X'·v' ; print('DOT')
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

			end
		end
	end
	return asb
end
