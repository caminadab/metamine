require 'unicode'
require 'exp'

local vbieb = bieb()

function numargs(functype)
	local argtype = arg0(functype)
	if fn(functype) == '→' and isobj(argtype) and obj(argtype) == ',' then
		if #argtype <= 4 then
			return #argtype
		end
	end
	return 1
end

local simpel = set('getal', 'int', 'bit', 'functie')
local cmp = set('>', '<', '=g', '≠', '≥', '≤')

local function issimpel(type)
	return not not simpel[atoom(type)]
end

local function isfunctie(exp)
	return atoom(exp) == 'functie' or fn(exp) == '→'
end

-- past types toe om operators te preoverloaden
function vectoriseer(asb, types, debug)
	local primair = {}
	local function rec(exp)
		primair[exp] = true
		if fn(exp) == '⇒' then
			rec(arg1(exp))
			if arg2(exp) then
				rec(arg2(exp))
			end
		end
		if fn(exp) == '⋀' then
			for i, sub in ipairs(arg(exp)) do
				rec(sub)
			end
		end
	end
	rec(asb)

	for exp in boompairsdfs(asb) do

		-- cmp
		if cmp[fn(exp)] then
			local atype  = types[moes(arg0(exp))]
			local btype  = types[moes(arg1(exp))]
			if isfunctie(atype) then
				if isfunctie(btype) then
					exp.f = X(fn(exp)..'f')
				else
					exp.f = X(fn(exp)..'f1')
				end
			end
		end

		-- filter2,3,4
		if fnaam(exp) == 'filter' or fnaam(exp) == 'map' then
			local type  = types[moes(exp)]
			local atype = types[moes(arg0(exp))]

			local functype = types[moes(arg1(exp)[2])]
			local num = numargs(functype)
			if num > 1 then
				exp.a[1] = X(atoom(exp.a[1])..'4')

				types[moes(exp)] = type
				types[moes(arg0(exp))] = atype
			end
		end

		-- cart tuple
		-- ((a,b)[] × c) -> ([(a,b)[] ×t c)
		-- ×l
		if fn(exp) == '×' then
			local atype    = types[moes(arg0(exp))]
			local itemtype = arg1(atype)
			if fn(atype) == '→' and obj(itemtype) == ',' then
				assign(exp.f, X'×t')
			end
		end

		-- call1,2,3,4
		if fn(exp) == '_' then
			local type = types[moes(arg0(exp))]
			--local argtype = arg0(type)
			local argtype = types[moes(arg1(exp))]
			if argtype then
				local args = arg1(exp)
				if false and issimpel(argtype) then
					local type = types[moes(exp)]
					--local nexp = substitueer(arg0(exp), X('_arg'), X('_arg0'))
					assign(exp, X('call1', arg0(exp), args))
					types[moes(exp)] = type
				end

				if obj(args) == ',' then
					local type = types[moes(exp)]
					if #args == 2 then
						assign(exp, X('call2', arg0(exp), args[1], args[2]))
					elseif #args == 3 then
						assign(exp, X('call3', arg0(exp), args[1], args[2], args[3]))
					elseif #args == 4 then
						assign(exp, X('call4', arg0(exp), args[1], args[2], args[3], args[4]))
					end
					types[moes(exp)] = type
				end
			end
		end

		-- rtti?
		if fn(exp) == '_' and atoom(arg0(exp)) == 'type' then
			local type = combineer(types[moes(arg1(exp))])
			local tekst = {o=X'"'}

			for i,u in utf8pairs(type) do
				tekst[i] = X(tostring(u))
			end
			--error(unlisp(tekst))
			assign(exp, tekst)
		end

		-- L_i → (_i)(L, i)
		if fn(exp) == '_' then
			local fntype = types[moes(arg0(exp))]
			local islijst = atoom(arg0(fntype)) == 'nat' or obj(fntype) == ','
			local istekst = fn(fntype) == '→' and atoom(arg0(fntype)) == 'nat' and atoom(arg1(fntype)) == 'letter'
			local isfunc = fn(fntype) == '→' and atoom(arg0(fntype)) ~= 'nat'

			if isfunc then
				local nargs = #arg0(fntype)
				if nargs > 4 then
					nargs = 1
				end
				--exp.f = X('call'..nargs)
				--exp.f = X('call')
				local args = exp.a[2]
				--print(moes(exp.a[2]))
					--error(combineer(exp))
				if false and nargs > 1 then
					-- clear
					for i,v in ipairs(exp.a) do
						exp.a[i] = nil
					end
					-- vul
					for i=1,nargs do
						exp.a[i] = X(',', X('index', args, tostring(i)))
					end
				end

				if nargs > 1 then
					exp.f = X'callm'
				else
					exp.f = X'call'
				end
			elseif istekst then
				exp.f = X'_t'
			elseif islijst then
				exp.f = X'index'
			else
				--print('Waarschuwing: vectortype van '..unlisp(exp)..' kon niet eenduidig worden bepaald')
			end
		end

		-- (X map [1,2,3]) → (X lmap [1,2,3])
		if fnaam(exp) == 'map' then
			local maptype = types[moes(arg2(exp))]
			if fn(maptype) == '→' and atoom(arg0(maptype)) == 'nat' then
				exp.a[1] = X'lmap'
			end
		end

		-- (F^i) → (^)(F, i)
		if fn(exp) == '^' then
			local basetype = types[moes(arg0(exp))]
			local islijst = atoom(arg0(basetype)) == 'nat'-- or obj(basetype) == ','
			local isfunc = fn(basetype) == '→' or atoom(basetype) == 'functie'
			if islijst then
				exp.f = X'^l'
			elseif isfunc then
				exp.f = X'^f'
			elseif atoom(basetype) == 'getal' or atoom(basetype) == 'int' then
				exp.f = X'^'
			else
				-- niets
			end
		end

		-- (1 = 2) ⇒ (1 =g 2)
		if not primair[exp] and fn(exp) == '=' or fn(exp) == '≠' then
			local type   = types[moes(exp)]
			local atype  = types[moes(arg0(exp))]
			local btype  = types[moes(arg1(exp))]
			local agetal = atoom(atype) == 'getal' or atoom(atype) == 'int' 
			local bgetal = atoom(btype) == 'getal' or atoom(btype) == 'int' 

			if moes(type) ~= 'ok' then

				if agetal or bgetal then
					exp.f = X(fn(exp)..'g')
				elseif atoom(atype) == 'bit' then
					--exp.f = X(fn(exp)..'g')
				end
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
			local isfuncB = fn(btype) == '→' or atoom(btype) == 'functie'
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
			elseif isfuncA and isfuncB then exp.f = X'+f'
			elseif isfuncA and isnumB then exp.f = X'+f1'
			elseif isfuncB and isnumA then
				exp.f = X'+f1' 
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

		-- (/) → /v | /v1 | /m | /m1 | /f
		if fn(exp) == '/' then
			local atype = types[moes(arg0(exp))]
			local btype = types[moes(arg1(exp))]
			local isnumA = atoom(atype) == 'int' or atoom(atype) == 'getal'
			local isnumB = atoom(btype) == 'int' or atoom(btype) == 'getal'
			local isfuncA = fn(atype) == '→' or atoom(atype) == 'functie'
			local isfuncB = fn(btype) == '→' or atoom(btype) == 'functie'
			local islijstA = atoom(arg0(atype)) == 'nat' or obj(atype) == ','
			local islijstB = atoom(arg0(btype)) == 'nat' or obj(btype) == ','
			local ismatA = atoom(arg0(atype)) == 'nat' and atoom(arg0(arg1(atype))) == 'nat'
			local ismatB = atoom(arg0(btype)) == 'nat' and atoom(arg0(arg1(btype))) == 'nat'
			--print(combineer(atype), combineer(btype))

			-- matrix
			if ismatA and ismatB then exp.f = X'/m' -- matrix multiplication!!
			elseif ismatA and islijstB then exp.f = X'/mv'
			elseif islijstA and ismatB then
				exp.f = X'/mv' 
				arg(exp)[1], arg(exp)[2] = arg(exp)[2], arg(exp)[1]
			elseif ismatA and isnumB then exp.f = X'/m1'
			elseif isnumA and ismatB then
				exp.f = X'/m1' 
				arg(exp)[1], arg(exp)[2] = arg(exp)[2], arg(exp)[1]

			-- vector
			elseif islijstA and islijstB then exp.f = X'/v' ;
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
			local isfuncB = fn(btype) == '→' or atoom(btype) == 'functie'
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
			elseif islijstA and islijstB then exp.f = X'·v'
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
