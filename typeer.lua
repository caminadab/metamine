require 'typegraaf'
require 'ontleed'
require 'symbool'
require 'func'
require 'fout'
require 'exp'

function typeer(exp)

local obj2sym = {
	[','] = symbool.tupel,
	['[]'] = X('→', 'nat', 'iets'),
	['{}'] = symbool.set,
	['"'] = X('→', 'nat', 'letter'),
	--['[]u'] = symbool.tekst,
}

local stdbron = ontleed(file('bieb/types.code'), 'bieb/types.code')
local std = {}

for i,feit in ipairs(stdbron.a) do
	for eq in boompairs(feit) do
		if fn(eq) == '_' and atoom(arg0(eq)) == 'lijst' then
			assign(eq, X('→', 'nat', arg1(eq)))
		end
		if atoom(eq) == 'lijst' then
			assign(eq, X('→', 'nat', 'iets'))
		end
	end
			
	if fn(feit) == ':' then
		local t,s = arg0(feit), arg1(feit)
		std[moes(t)] = s
	end
end

local calls = set('call', 'call2', 'call3', 'call4')
local function fnaam(exp)
	return (fn(exp) == '_' or calls[fn(exp)]) and atoom(arg0(exp))
end

function linkbieb(typegraaf)
	for i,feit in ipairs(stdbron.a) do
		if fn(feit) == ':' then
			local t,s = arg0(feit), arg1(feit)
			local t = kopieer(t)
			local s = kopieer(s)
			typegraaf:maaktype(t, s)
		end
	end
	return typegraaf
end

-- makkelijke types (getallen & standaardatomen)
local function eztypeer(exp)
	if isatoom(exp) then
		if tonumber(atoom(exp)) then
			if atoom(exp) % 1 == 0 then
				return kopieer(symbool.int)
			else
				return kopieer(symbool.getal)
			end
		elseif std[moes(exp)] then
			return kloon(std[moes(exp)])
		end
	elseif isobj(exp) then
		return obj2sym[obj(exp)]
	end
end

-- exp → type, fouten
	local typegraaf = linkbieb(maaktypegraaf())
	local types = {} -- moes → type
	local permoes = permoes(exp) -- moes → moezen
	local fouten = {}
	local maakvar = maakvars()

	-- track
	local _types
	if verbozeTypes then
	_types = {}
	setmetatable(types, {
		__index = function(t,k) return _types[k] end;
		__newindex = function(t,k,v)
			v.var = v.var or maakvar()
			if false and k == 'uit' and moes(v) ~= 'iets' then
				assert(false)
			end
			print('TYPEER', k..': '..combineer(v))
			_types[k] = v
		end
	})
	end

	-- ta := ta ∩ tb
	function moetzijn(ta, tb, exp)
		assert(ta)
		assert(tb)

		if ta == tb then return ta end

		ta.var = ta.var or maakvar()

		check(ta)
		check(tb)
		check(exp)
		local intersectie,fout = typegraaf:intersectie(ta, tb, exp)

		if not intersectie then
			fouten[#fouten+1] = fout
		elseif intersectie then
			ta = intersectie
		end

		return ta
	end

	function typeerrec(exp)
		local ez = eztypeer(exp)

		for k,sub in subs(exp) do
			typeerrec(sub)
		end

		if obj(exp) == ',' then
			local m = moes(exp)
			local t = {o=X','}
			for i,sub in ipairs(exp) do
				local subtype = assert(types[moes(sub)], 'geen type voor kind '..moes(sub))
				t[i] = subtype
			end
			types[m] = t

		elseif obj(exp) == '[]' then
			local lijsttype = exp[1] and types[moes(exp[1])] or X'iets'
			for i,sub in ipairs(exp) do
				local subtype = assert(types[moes(sub)], 'geen type voor kind '..moes(sub))
				local fout
				lijsttype,fout = typegraaf:intersectie(subtype, lijsttype, sub) --moetzijn(lijsttype, subtype, sub)
				if not lijsttype then
					lijsttype = X'iets'
					fouten[#fouten+1] = fout
				end
				types[moes(sub)] = lijsttype
			end

			-- metamine ondersteunt geen gemixte lijsten; gebruik tupels!
			if false and atoom(lijsttype) == 'iets' then
				local fout = typeerfout(exp.loc, "type van {code} is onzeker", bron(exp))
				fouten[#fouten+1] = fout
			end

			local type = typegraaf:maaktype(X('→', 'nat', lijsttype))
			if #exp > 0 then
				types[moes(exp)] = type
			else
				types[moes(exp)] = X('→', 'nat', 'iets')
			end

		-- min
		elseif fn(exp) == '-' then
			types[moes(exp)] = types[moes(arg(exp))]


		-- vanaf: lijst(A), int → lijst(A)
		elseif fnaam(exp) == 'vanaf' then
			local A = moes(arg1(exp))
			moetzijn(types[A], X(',', 'iets', 'iets'), exp)

			local lijst = types[A][1]
			local index = types[A][2]

			moetzijn(lijst, X('→', 'nat', 'iets'), lijst or exp)
			moetzijn(index, X'int', lijst or exp)

			types[moes(exp)] = lijst


		-- tot: lijst(A), int → lijst(A)
		elseif fnaam(exp) == 'tot' then
			local A = moes(arg1(exp))
			moetzijn(types[A], X(',', 'iets', 'iets'), exp)

			local lijst = types[A][1]
			local index = types[A][2]

			moetzijn(lijst, X('→', 'nat', 'iets'), lijst or exp)
			moetzijn(index, X'int', lijst or exp)

			types[moes(exp)] = lijst


		-- deel: lijst(A), int, int → lijst(A)
		elseif fnaam(exp) == 'deel' then
			local A = moes(arg1(exp))
			moetzijn(types[A], X(',', 'iets', 'iets', 'iets'), exp)

			local lijst = types[A][1]
			local van = types[A][2]
			local tot = types[A][3]

			moetzijn(lijst, X('→', 'nat', 'iets'), lijst or exp)
			moetzijn(van, X'int', lijst or exp)
			moetzijn(tot, X'int', lijst or exp)

			types[moes(exp)] = lijst


		-- _(zip, (lijst, fn))
		elseif fnaam(exp) == 'zip' then
			local A = moes(arg1(exp))
			moetzijn(types[A], X(',', 'iets', 'iets'), exp)

			local lijstA = types[A][1]
			local lijstB = types[A][2]

			moetzijn(lijstA, X('→', 'nat', 'iets'), lijst or exp)
			moetzijn(lijstB, X('→', 'nat', 'iets'), lijst or exp)

			local uittype = X(',', arg1(lijstA), arg1(lijstB))
			types[moes(exp)] = X('→', 'nat', uittype)

		-- _(reduceer, (init, lijst, func))
		elseif fnaam(exp) == 'reduceer' then
			local redarg = arg1(exp)
			local I = moes(redarg[1])
			local L = moes(redarg[2])
			local F = moes(redarg[3])

			local inittype  = types[I]
			local lijsttype = types[L]
			local functype  = types[F]

			local itemtype = arg1(lijsttype) or arg1(functype)

			-- reduceer(I, (N→B), (I,B → I))
			-- I@1 = I@3
			-- I@3 = I@3
			-- B@2 = B@3
			moetzijn(lijsttype, X('→', 'nat', itemtype), arg1(exp)[2])
			moetzijn(functype, X('→', X(',', inittype, itemtype), inittype), arg1(exp)[3])

			print('init',combineer(inittype))
			print('lijst',combineer(lijsttype))
			print('func',combineer(functype))
			print('item',combineer(itemtype))

			types[moes(exp)] = typegraaf:maaktype(inittype)

		-- _(map, (lijst, fn))
		elseif fnaam(exp) == 'map' then
			local A = moes(arg1(exp))
			moetzijn(types[A], X(',', 'iets', 'iets'), exp)

			local lijst   = types[A][1]
			local functie = types[A][2]

			local intype = X'iets'
			local uittype = X'iets'

			moetzijn(lijst, X('→', 'nat', intype), lijst)
			moetzijn(functie, X('→', intype, uittype), functie)

			types[moes(exp)] = X('→', 'nat', uittype)

		-- _(filter, (lijst, fn))
		elseif fnaam(exp) == 'filter' then
			local A = moes(arg1(exp))
			moetzijn(types[A], X(',', 'iets', 'iets'), exp)

			local lijst   = types[A][1]
			local functie = types[A][2]

			local intype = X'iets'

			moetzijn(lijst, X('→', 'nat', intype), lijst)
			moetzijn(functie, X('→', intype, 'bit'), functie)

			types[moes(exp)] = lijst

		-- _(map, (lijst, fn))
		elseif fn(exp) == '_' and atoom(arg0(exp)) == 'map2' then
			local l = arg1(exp)[1]
			local f = arg1(exp)[2]
			-- lijst
			local A = moes(l)
			-- functie
			local B = moes(f)

			moetzijn(types[A], X('→', 'nat', 'iets'), arg0(exp))
			local lijsttype = arg1(types[A])
			moetzijn(types[B], X('→', lijsttype, 'iets'), arg1(exp))

			local lijsttype = arg1(types[A])
			local uittype = arg1(types[B]) or X'iets'

			moetzijn(types[A], X('→', 'nat', lijsttype), arg0(exp))
			moetzijn(types[B], X('→', lijsttype, uittype), arg1(exp))

			--moetzijn(lijsttype, arg1(types[B]))

			local type = typegraaf:maaktype(X('→', 'nat', uittype)) --arg1(types[B])))
			types[moes(exp)] = type
			--print('maptype', combineer(types[B]))

		-- cart
		elseif fn(exp) == '×' then
			local A = moes(arg0(exp))
			local B = moes(arg1(exp))
			moetzijn(types[A], X('→', 'nat', 'iets'), arg0(exp))
			local lijsttypeA = arg1(types[A])

			moetzijn(types[B], X('→', 'nat', 'iets'), arg1(exp))
			local lijsttypeB = arg1(types[B])

			--moetzijn(lijsttypeA, X'tupel', 

			if obj(lijsttypeA) == ',' then
				lijsttype =  {o=X','}
				for i, v in ipairs(lijsttypeA) do
					lijsttype[i] = v
				end
				lijsttype[#lijsttype+1] = lijsttypeB
			else
				lijsttype = X(',', lijsttypeA, lijsttypeB)
			end

			--print('LIJSTTYPE', combineer(lijsttype))

			types[moes(exp)] = X('→', 'nat', lijsttype)
			--error(combineer(types[moes(exp)]))

		-- plus
		elseif fn(exp) == '+' or fn(exp) == '·' or fn(exp) == '/' then
			local A = moes(arg0(exp))
			local B = moes(arg1(exp))
			local geengetalA = atoom(types[A]) ~= 'int' and atoom(types[A]) ~= 'getal'
			local geengetalB = atoom(types[B]) ~= 'int' and atoom(types[B]) ~= 'getal'

			local ismatA = atoom(arg0(types[A])) == 'nat' and atoom(arg0(arg1(types[A]))) == 'nat'
			local ismatB = atoom(arg0(types[B])) == 'nat' and atoom(arg0(arg1(types[B]))) == 'nat'
			
			--print(A, B, geengetalA, geengetalB, ismatA, ismatB)
			--error'OK'

			-- matvec, matmat
			if geengetalB then
				types[moes(exp)] = types[B]
				--print('MATVEC/MAT', combineer(types[moes(exp)]))

			-- mat1
			elseif ismatA then
				types[moes(exp)] = types[A]

			-- dot
			elseif fn(exp) == '·' and geengetalA and geengetalB then
				types[moes(exp)] = X'getal'
			elseif types[A] and geengetalA then
				types[moes(exp)] = types[A]
			else
				types[moes(exp)] = types[B]
			end

		-- machtsverheffing
		elseif fn(exp) == '^' then
			local A = moes(arg0(exp))
			local B = moes(arg1(exp))

			--moetzijn(types[A], 
			types[moes(exp)] = types[A]

		-- concatenatie
		elseif true and fn(exp) == '‖' then
			local A = moes(arg0(exp))
			local B = moes(arg1(exp))

			moetzijn(types[A], X('→', 'nat', 'iets'), exp)
			moetzijn(types[B], X('→', 'nat', 'iets'), exp)

			--print('CAT A', A, e2s(types[A]))
			--print('CAT B', B, e2s(types[B]))

			local lijsttypeA = types[A]
			local lijsttypeB = types[B]
			local lijsttype = typegraaf:intersectie(lijsttypeA, lijsttypeB, exp)
			if not lijsttype then
				local fout = typeerfout(exp.loc, "{code}: ongeldige concatenatie van {exp} en {exp}", bron(exp), lijsttypeA, lijsttypeB)
				fouten[#fouten+1] = fout
				lijsttype = X('→', 'nat', 'iets')
			end

			--print("CAT", combineer(lijsttypeA), combineer(lijsttypeB), combineer(lijsttype))

				--lijsttype = X('→', 'nat', 'iets')
			types[moes(exp)] = lijsttype

		elseif fn(exp) == '=' or fn(exp) == ':=' then
			local A = moes(arg0(exp))
			local B = moes(arg1(exp))
			assert(types[A])
			assert(types[B])
			-- verandert types[A] -- bewust!! dit voorkomt substitutie
			--error(C(exp))
			local T = moetzijn(types[A], types[B], arg0(exp))
			types[A] = T
			types[B] = T
			types[moes(exp)] = symbool.bit
			types[moes(arg(exp))] = typegraaf:maaktype(X(',', T, T))

		elseif fn(exp) == '⋀' then
			types[moes(exp)] = symbool.bit

		elseif fn(exp) == 'zolang' then
			local A = types[moes(arg0(exp))]
			local B = types[moes(arg1(exp))]

			moetzijn(A, symbool.bit, arg0(exp))
			types[moes(exp)] = X'iets'

		elseif fn(exp) == '⇒' then
			local A = types[moes(arg0(exp))]
			local B = types[moes(arg1(exp))]

			moetzijn(A, symbool.iets, arg0(exp)) -- TODO bit
			types[fn(exp)] = X'functie'
			types[moes(exp)] = B

		elseif fn(exp) == "'" then
			local A = types[moes(exp.a)]
			types[moes(exp)] = A
			types["'"] = X'functie'

		-- compositie
		elseif fn(exp) == '∘' then
			local A = types[moes(arg0(exp))]
			local B = types[moes(arg1(exp))]
			local anyfuncA = X('→', 'iets', 'iets')
			local anyfuncB= X('→', 'iets', 'iets')

			moetzijn(A, anyfuncA, arg0(exp))
			moetzijn(B, anyfuncB, arg1(exp))

			local  inA = arg0(A)
			local uitA = arg1(A)
			local  inB = arg0(B)
			local uitB = arg1(B)
				
			if not (inA and uitA and inB and uitB) then
				local fout = typeerfout(exp.loc,
					"compositiefout in {code}: kan {exp} en {exp} niet componeren",
					bron(exp), A, B)
				fouten[#fouten+1] = fout
				types[moes(exp)] = kopieer(symbool.iets)
				return
			end

			-- compo
			local compositie = X('→', inA, uitB)

			local inter = moetzijn(uitA, inB, arg1(exp))
			--assign(A.a[2], inter)
			--assign(B.a[1], inter)
			--moetzijn(arg1(A), inter)
			--moetzijn(arg0(B), inter)
			A.a[2] = inter
			B.a[1] = inter

			types[moes(exp)] = compositie

		elseif false and fn(exp) == '_f' and atoom(arg0(exp)) == 'vouw' then
			types['vouw'] = X'functie'
			types[moes(exp)] = X'iets'

		---------- linq
		-- vouw: lijst(A), (A,A → B) → lijst(B)
		elseif false and fn(exp) == '_f' and atoom(arg0(exp)) == 'vouw' then
			local expargs = types[moes(arg1(exp))]

			--print('expargs1', combineer(expargs))
			local anya = X'iets'
			local anyb = X'iets'
			local lijsta = X('→', 'nat', anya)
			local anyfunc = X('→', X(',', anya, anya), anyb)

			-- A,A → B
			local anyargs = X(',', lijsta, anyfunc)

			local expargs = moetzijn(expargs, anyargs, arg1(exp))

			-- (A,A → B), lijst(A)   ⇒   lijst(A) = A, lijst(B) = B
			-- lijst, fn
			--print('expargs2', combineer(expargs))

			-- vouw: lijst(A), (A,A → B)
			local lijst = expargs[1]
			local func  = expargs[2]
			local funcargs = arg0(func)

			--funcargs.a[1] = moetzijn(funcargs.a[1], expargs
			--print(combineer(arg(lijst)), combineer((funcargs)))
			moetzijn(arg1(lijst), funcargs[1], exp)

			--[[
			print('VOUW')
			print(combineer(funcargs[1]))
			print(combineer(funcargs[2]))
			print(combineer(lijst))
			]]

			funcargs[1] = moetzijn(funcargs[1], arg1(lijst), exp)
			funcargs[2] = moetzijn(funcargs[2], funcargs[1], exp)
			lijst.a[2] = funcargs[1]
			--error(C(anya))

			moetzijn(arg1(lijsta), anya, exp)
			local sub = X('resultaat van '..C(arg1(exp)[2]))
			sub.loc = exp.loc
			moetzijn(arg1(lijsta), arg1(func), sub) -- TODO

			-- A,A → B  ⇒ arg₀ = arg₁ 
			moetzijn(arg0(anyfunc)[1], arg0(anyfunc)[2], exp)

			types['vouw'] = X'functie'
			types[moes(exp)] = arg1(func)


		-- indexeer
		-- a _ b  :  ((X→Y) _ X) :  Y
		elseif fn(exp) == '_' then
			local functype = types[moes(arg0(exp))] -- type(a)  = X→Y
			local argtype = types[moes(arg1(exp))]  -- type(b)  = X
			assert(functype)
			assert(argtype)

			--print('____', combineer(argtype), combineer(functype), combineer(exp), combineer(argtype))

			local funcarg, returntype

			if fn(functype) == '→' then
				funcarg = moetzijn(argtype, arg0(functype), arg1(exp))
				functype.a[1] = funcarg
				returntype = arg1(functype)

				--error(C(arg0(functype)))

			elseif obj(functype) == ',' then
				returntype = X'iets' --{f=X'|', a=functype}

			else

				local anyfunc = X('→', 'iets', 'iets')
				--moetzijn(functype, anyfunc, arg0(exp))

				if fn(functype) ~= '→' then
					returntype = X'iets'

				else
					--print('FUNCTYPE', combineer(functype))
					--print('ARGTYPE', combineer(argtype))
					moetzijn(arg0(functype), argtype, exp)

					returntype = arg1(functype)
				end

				--[[
				local fout = typeerfout(exp.loc or nergens,
					"{code}: ongeldig functieargument {exp} voor {exp}",
					bron(exp), argtype, functype
				)
				fouten[#fouten+1] = fout
				--error(C(functype))
				--returntype = typegraaf:maaktype(X'fout')
				returntype = X'iets'
				]]

			end

			types[moes(exp)] = returntype

		elseif fn(exp) == '→' then
			local f = arg0(exp)
			local a = arg1(exp)

			local F = moes(f)
			local A = moes(a)

			-- tf : A → B
			-- tg : B → C
			local tf = types[F]
			local ta = types[A]
			
			-- a → b
			local ftype = X('→', tf, ta)
			--moetzijn(a, 10)
			--error'OK'
			--moetzijn(a, 10, exp)
			-- TODO
			--types[moes(exp)] = types[moes(exp)] or kopieer(arg1(std.functie))
			--moetzijn(types[moes(exp)], ftype, exp)
			types[moes(exp)] = ftype

		elseif fn(exp) == ':' then
			local doel,type = arg0(exp), arg1(exp)
			local type = typegraaf:maaktype(type)
			--moetzijn(doel, type, arg0(exp)) -- TODO
			types[moes(exp)] = symbool.bit
			types[fn(exp)] = symbool.bit
 
		elseif ez then
			types[moes(exp)] = ez

		-- standaardtypes
		elseif std[fn(exp)] then
			local stdtype = kloon(std[fn(exp)])
			--local argtype = types[moes(arg(exp))]
			local argtype = types[moes(arg(exp))]
			local inn, uit = arg0(stdtype), arg1(stdtype)

			-- typeer arg
			types[moes(exp.a)] = types[moes(exp.a)] or inn
			--print('ARGTYPE voor', combineer(argtype), combineer(inn), combineer(exp.a))
			local sub = exp.a
			if not sub then
				sub = X('argument van '..combineer(exp))
				sub.loc = exp.loc
			end
			moetzijn(argtype, inn, sub)

			-- typeer exp
			--types[moes(exp.a)] = argtype
			types[moes(exp)] = uit

		else
			local m = moes(exp)
			if isvar(m) then
				error'OK'
			end
			types[m] = types[m] or X'iets'

		end

	end

	typeerrec(exp)

	--do return types[moes(exp)], fouten, types end

	-- is alles getypeerd?
	for moes,exps in pairs(permoes) do
		if false and (not types[moes] or _G.moes(types[moes]) == 'iets')
				and not std[moes]
				and not typegraaf.types[moes]
				then
				--and moes:sub(1,1) ~= ',' then
			local exp = exps[1]
			local fout = typeerfout(exp.loc or nergens,
				"kon type niet bepalen van {code}",
				isobj(exp) and combineer(exp) or locsub(exp.code, exp.loc)
			)
			fouten[#fouten+1] = fout
		end
	end

	if verbozeTypes then
		print '# Eindtypes'
		for moes,type in pairs(_types or types) do
			print('EINDTYPE', type.var, moes, combineer(type))
		end
	end

	if verbozeTypes then
		types = _types or types
	end

	return types[moes(exp)], fouten, types
end

