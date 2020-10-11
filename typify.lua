require 'typegraph'
require 'parse'
require 'symbol'
require 'func'
require 'fout'
require 'exp'

function typify(exp)

local obj2sym = {
	[','] = symbol.tupel,
	['[]'] = X('→', 'nat', 'iets'),
	['{}'] = symbol.set,
	['"'] = X('→', 'nat', 'letter'),
	--['[]u'] = symbol.text,
}

local stdbron = parse(file('lib/types.code'), 'lib/types.code')
local std = {}

for i,feit in ipairs(stdbron.a) do
	for eq in treepairs(feit) do
		if fn(eq) == '_' and atom(arg0(eq)) == 'lijst' then
			assign(eq, X('→', 'nat', arg1(eq)))
		end
		if atom(eq) == 'lijst' then
			assign(eq, X('→', 'nat', 'iets'))
		end
	end
			
	if fn(feit) == ':' then
		local t,s = arg0(feit), arg1(feit)
		std[hash(t)] = s
	end
end

local calls = set('call', 'call2', 'call3', 'call4')
local function fname(exp)
	return (fn(exp) == '_' or calls[fn(exp)]) and atom(arg0(exp))
end

function linklib(typegraph)
	for i,feit in ipairs(stdbron.a) do
		if fn(feit) == ':' then
			local t,s = arg0(feit), arg1(feit)
			local t = copy(t)
			local s = copy(s)
			typegraph:maaktype(t, s)
		end
	end
	return typegraph
end

-- makkelijke types (getallen & standaardatomen)
local function eztypify(exp)
	if isatom(exp) then
		if tonumber(atom(exp)) then
			if atom(exp) % 1 == 0 then
				return copy(symbol.int)
			else
				return copy(symbol.getal)
			end
		elseif std[hash(exp)] then
			return clone(std[hash(exp)])
		end
	elseif isobj(exp) then
		return obj2sym[obj(exp)]
	end
end

-- exp → type, errors
	local typegraph = linklib(maaktypegraph())
	local types = {} -- hash → type
	local perhash = perhash(exp) -- hash → moezen
	local errors = {}
	local makevar = makevars()

	-- track
	local _types
	if verbozeTypes then
	_types = {}
	setmetatable(types, {
		__index = function(t,k) return _types[k] end;
		__newindex = function(t,k,v)
			v.var = v.var or makevar()
			if false and k == 'uit' and hash(v) ~= 'iets' then
				assert(false)
			end
			local f = debug.traceback():gmatch(':(%d+):')
			f()
			local l = f()
			print('TYPEER', 'L'..l.. '\t'.. k..'\t'..deparse(v))
			_types[k] = v
		end
	})
	end

	-- ta := ta ∩ tb
	function moetzijn(ta, tb, exp)
		assert(ta)
		assert(tb)

		if ta == tb then return ta end

		ta.var = ta.var or makevar()

		check(ta)
		check(tb)
		check(exp)
		local intersectie,fout = typegraph:intersectie(ta, tb, exp)

		if not intersectie then
			errors[#errors+1] = fout
		elseif intersectie then
			ta = intersectie
		end

		return ta
	end

	function typifyrec(exp)
		local ez = eztypify(exp)

		for k,sub in subs(exp) do
			typifyrec(sub)
		end

		if obj(exp) == ',' then
			local m = hash(exp)
			local t = {o=X','}
			for i,sub in ipairs(exp) do
				local subtype = assert(types[hash(sub)], 'no type for node '..hash(sub))
				t[i] = subtype
			end
			types[m] = t

		elseif obj(exp) == '[]' then
			local lijsttype = exp[1] and types[hash(exp[1])] or X'iets'
			for i,sub in ipairs(exp) do
				local subtype = assert(types[hash(sub)], 'no type for node '..hash(sub))
				local fout
				lijsttype,fout = typegraph:intersectie(subtype, lijsttype, sub) --moetzijn(lijsttype, subtype, sub)
				if not lijsttype then
					lijsttype = X'iets'
					errors[#errors+1] = fout
				end
				types[hash(sub)] = lijsttype
			end

			-- metamine ondersteunt geen gemixte lijsten; gebruik tupels!
			if false and atom(lijsttype) == 'iets' then
				local fout = typifyfout(exp.loc, "type of {code} is uncertain", bron(exp))
				errors[#errors+1] = fout
			end

			local type = typegraph:maaktype(X('→', 'nat', lijsttype))
			if #exp > 0 then
				types[hash(exp)] = type
			else
				types[hash(exp)] = X('→', 'nat', 'iets')
			end

		-- min
		elseif fn(exp) == '-' then
			types[hash(exp)] = types[hash(arg(exp))]


		-- vanaf: lijst(A), int → lijst(A)
		elseif fname(exp) == 'vanaf' then
			local A = hash(arg1(exp))
			moetzijn(types[A], X(',', 'iets', 'iets'), exp)

			local lijst = types[A][1]
			local index = types[A][2]

			moetzijn(lijst, X('→', 'nat', 'iets'), lijst or exp)
			moetzijn(index, X'int', lijst or exp)

			types[hash(exp)] = lijst


		-- tot: lijst(A), int → lijst(A)
		elseif fname(exp) == 'tot' then
			local A = hash(arg1(exp))
			moetzijn(types[A], X(',', 'iets', 'iets'), exp)

			local lijst = types[A][1]
			local index = types[A][2]

			moetzijn(lijst, X('→', 'nat', 'iets'), lijst or exp)
			moetzijn(index, X'int', lijst or exp)

			types[hash(exp)] = lijst


		-- deel: lijst(A), int, int → lijst(A)
		elseif fname(exp) == 'deel' then
			local A = hash(arg1(exp))
			moetzijn(types[A], X(',', 'iets', 'iets', 'iets'), exp)

			local lijst = types[A][1]
			local van = types[A][2]
			local tot = types[A][3]

			moetzijn(lijst, X('→', 'nat', 'iets'), lijst or exp)
			moetzijn(van, X'int', lijst or exp)
			moetzijn(tot, X'int', lijst or exp)

			types[hash(exp)] = lijst


		-- _(zip, (lijst, fn))
		elseif fname(exp) == 'rits' then
			local A = hash(arg1(exp))
			moetzijn(types[A], X(',', 'iets', 'iets'), exp)

			local lijstA = types[A][1]
			local lijstB = types[A][2]

			moetzijn(lijstA, X('→', 'nat', 'iets'), lijst or exp)
			moetzijn(lijstB, X('→', 'nat', 'iets'), lijst or exp)

			local uittype = X(',', arg1(lijstA), arg1(lijstB))
			types[hash(exp)] = X('→', 'nat', uittype)

		-- _(reduceer, (init, lijst, func))
		elseif fname(exp) == 'reduceer' then
			local redarg = arg1(exp)
			local I = hash(redarg[1])
			local L = hash(redarg[2])
			local F = hash(redarg[3])

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

			--print('init',deparse(inittype))
			--print('lijst',deparse(lijsttype))
			--print('func',deparse(functype))
			--print('item',deparse(itemtype))

			types[hash(exp)] = typegraph:maaktype(inittype)

		-- _(map, (lijst, fn))
		elseif fname(exp) == 'map' then
			local A = hash(arg1(exp))
			moetzijn(types[A], X(',', 'iets', 'iets'), exp)

			local lijst   = types[A][1]
			local functie = types[A][2]

			local intype = X'iets'
			local uittype = X'iets'

			moetzijn(lijst, X('→', 'nat', intype), lijst)
			moetzijn(functie, X('→', intype, uittype), functie)

			types[hash(exp)] = X('→', 'nat', uittype)

		-- _(filter, (lijst, fn))
		elseif fname(exp) == 'filter' then
			local A = hash(arg1(exp))
			moetzijn(types[A], X(',', 'iets', 'iets'), exp)

			local lijst   = types[A][1]
			local functie = types[A][2]

			local intype = X'iets'

			moetzijn(lijst, X('→', 'nat', intype), lijst)
			moetzijn(functie, X('→', intype, 'bit'), functie)

			types[hash(exp)] = lijst

		-- _(map, (lijst, fn))
		elseif fn(exp) == '_' and atom(arg0(exp)) == 'map2' then
			local l = arg1(exp)[1]
			local f = arg1(exp)[2]
			-- lijst
			local A = hash(l)
			-- functie
			local B = hash(f)

			moetzijn(types[A], X('→', 'nat', 'iets'), arg0(exp))
			local lijsttype = arg1(types[A])
			moetzijn(types[B], X('→', lijsttype, 'iets'), arg1(exp))

			local lijsttype = arg1(types[A])
			local uittype = arg1(types[B]) or X'iets'

			moetzijn(types[A], X('→', 'nat', lijsttype), arg0(exp))
			moetzijn(types[B], X('→', lijsttype, uittype), arg1(exp))

			--moetzijn(lijsttype, arg1(types[B]))

			local type = typegraph:maaktype(X('→', 'nat', uittype)) --arg1(types[B])))
			types[hash(exp)] = type
			--print('maptype', deparse(types[B]))

		-- cart
		elseif fn(exp) == '×' then
			local A = hash(arg0(exp))
			local B = hash(arg1(exp))
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

			--print('LIJSTTYPE', deparse(lijsttype))

			types[hash(exp)] = X('→', 'nat', lijsttype)
			--error(deparse(types[hash(exp)]))

		-- plus
		elseif fn(exp) == '+' or fn(exp) == '·' or fn(exp) == '/' then
			local A = hash(arg0(exp))
			local B = hash(arg1(exp))
			local geengetalA = atom(types[A]) ~= 'int' and atom(types[A]) ~= 'getal'
			local geengetalB = atom(types[B]) ~= 'int' and atom(types[B]) ~= 'getal'

			local ismatA = atom(arg0(types[A])) == 'nat' and atom(arg0(arg1(types[A]))) == 'nat'
			local ismatB = atom(arg0(types[B])) == 'nat' and atom(arg0(arg1(types[B]))) == 'nat'
			
			--print(A, B, geengetalA, geengetalB, ismatA, ismatB)
			--error'OK'

			-- matvec, matmat
			if geengetalB then
				types[hash(exp)] = types[B]
				--print('MATVEC/MAT', deparse(types[hash(exp)]))

			-- mat1
			elseif ismatA then
				types[hash(exp)] = types[A]

			-- dot
			elseif fn(exp) == '·' and geengetalA and geengetalB then
				types[hash(exp)] = X'getal'
			elseif types[A] and geengetalA then
				types[hash(exp)] = types[A]
			else
				-- twee getallen
				if fn(exp) == '/' then
					types[hash(exp)] = X'getal'
				elseif fn(exp) == '·' then
					if atom(types[A]) == 'int' and atom(types[B]) == 'int' then
						types[hash(exp)] = X'int'
					elseif not geengetalA and not geengetalB then
						types[hash(exp)] = X'getal'
					end
				else
					types[hash(exp)] = types[A]
				end
			end

		-- machtsverheffing
		elseif fn(exp) == '^' then
			local A = hash(arg0(exp))
			local B = hash(arg1(exp))

			--moetzijn(types[A], 
			types[hash(exp)] = types[A]

		-- concatenatie
		elseif true and fn(exp) == '‖' then
			local A = hash(arg0(exp))
			local B = hash(arg1(exp))

			moetzijn(types[A], X('→', 'nat', 'iets'), exp)
			moetzijn(types[B], X('→', 'nat', 'iets'), exp)

			--print('CAT A', A, e2s(types[A]))
			--print('CAT B', B, e2s(types[B]))

			local lijsttypeA = types[A]
			local lijsttypeB = types[B]
			local lijsttype = typegraph:intersectie(lijsttypeA, lijsttypeB, exp)
			if not lijsttype then
				local fout = typifyfout(exp.loc, "{code}: ongeldige concatenatie van {exp} en {exp}", bron(exp), lijsttypeA, lijsttypeB)
				errors[#errors+1] = fout
				lijsttype = X('→', 'nat', 'iets')
			end

			--print("CAT", deparse(lijsttypeA), deparse(lijsttypeB), deparse(lijsttype))

				--lijsttype = X('→', 'nat', 'iets')
			types[hash(exp)] = lijsttype

		elseif fn(exp) == '=' or fn(exp) == ':=' then
			local A = hash(arg0(exp))
			local B = hash(arg1(exp))
			assert(types[A])
			assert(types[B])
			-- verandert types[A] -- bewust!! dit voorkomt substitutie
			--error(C(exp))
			local T = moetzijn(types[A], types[B], arg0(exp))
			types[A] = T
			types[B] = T
			types[hash(exp)] = symbol.bit
			types[hash(arg(exp))] = typegraph:maaktype(X(',', T, T))

		elseif fn(exp) == '⋀' then
			types[hash(exp)] = symbol.bit

		elseif fn(exp) == 'zolang' then
			local A = types[hash(arg0(exp))]
			local B = types[hash(arg1(exp))]

			moetzijn(A, symbol.bit, arg0(exp))
			types[hash(exp)] = X'iets'

		elseif fn(exp) == '⇒' then
			local A = types[hash(arg0(exp))]
			local B = types[hash(arg1(exp))]
			local C = arg2(exp) and types[hash(arg2(exp))]

			moetzijn(A, symbol.iets, arg0(exp)) -- TODO bit
			types[fn(exp)] = X'functie'
			types[hash(exp)] = B

		elseif fn(exp) == "'" then
			local A = types[hash(exp.a)]
			types[hash(exp)] = A
			types["'"] = X'functie'

		-- compositie
		elseif fn(exp) == '∘' then
			local A = types[hash(arg0(exp))]
			local B = types[hash(arg1(exp))]
			local anyfuncA = X('→', 'iets', 'iets')
			local anyfuncB= X('→', 'iets', 'iets')

			moetzijn(A, anyfuncA, arg0(exp))
			moetzijn(B, anyfuncB, arg1(exp))

			local  inA = arg0(A)
			local uitA = arg1(A)
			local  inB = arg0(B)
			local uitB = arg1(B)
				
			if not (inA and uitA and inB and uitB) then
				local fout = typifyfout(exp.loc,
					"compose error in {code}: cannot compose {exp} and {exp}",
					bron(exp), A, B)
				errors[#errors+1] = fout
				types[hash(exp)] = copy(symbol.iets)
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

			types[hash(exp)] = compositie

		elseif false and fn(exp) == '_f' and atom(arg0(exp)) == 'vouw' then
			types['vouw'] = X'functie'
			types[hash(exp)] = X'iets'

		---------- linq
		-- vouw: lijst(A), (A,A → B) → lijst(B)
		elseif false and fn(exp) == '_f' and atom(arg0(exp)) == 'vouw' then
			local expargs = types[hash(arg1(exp))]

			--print('expargs1', deparse(expargs))
			local anya = X'iets'
			local anyb = X'iets'
			local lijsta = X('→', 'nat', anya)
			local anyfunc = X('→', X(',', anya, anya), anyb)

			-- A,A → B
			local anyargs = X(',', lijsta, anyfunc)

			local expargs = moetzijn(expargs, anyargs, arg1(exp))

			-- (A,A → B), lijst(A)   ⇒   lijst(A) = A, lijst(B) = B
			-- lijst, fn
			--print('expargs2', deparse(expargs))

			-- vouw: lijst(A), (A,A → B)
			local lijst = expargs[1]
			local func  = expargs[2]
			local funcargs = arg0(func)

			--funcargs.a[1] = moetzijn(funcargs.a[1], expargs
			--print(deparse(arg(lijst)), deparse((funcargs)))
			moetzijn(arg1(lijst), funcargs[1], exp)

			--[[
			print('VOUW')
			print(deparse(funcargs[1]))
			print(deparse(funcargs[2]))
			print(deparse(lijst))
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
			types[hash(exp)] = arg1(func)


		-- indexeer
		-- a _ b  :  ((X→Y) _ X) :  Y
		-- A: X → Y
		-- B: A _ X
		-- C: (B : Y)
		elseif fn(exp) == '_' then
			local functype = types[hash(arg0(exp))] -- type(a)  = X→Y
			local argtype = types[hash(arg1(exp))]  -- type(b)  = X
			local funcarg, returntype

			assert(functype)
			assert(argtype)

			local returntype = X'iets' --X(color.green..'iets'..color.white)

			moetzijn(functype, X('→', argtype, returntype), exp)
			types[hash(arg0(exp))] = functype
			--types[hash(exp)] = func
			
			--error(deparse(functype))

			--print('____', deparse(argtype), deparse(functype), deparse(exp), deparse(argtype))
			--types[hash(arg0(exp))] = functype


			if fn(functype) == '→' then
				funcarg = moetzijn(argtype, arg0(functype), arg1(exp))
				returntype = arg1(functype)
				functype.a[1] = funcarg

				returntype = arg1(functype)

				--error(C(functype))

			elseif obj(functype) == ',' then
				local index = atom(arg1(exp))
				local n = tonumber(index)
				if not n then
					local fout = typifyfout(exp.loc, "tupels kunnen niet dynamic worden geïndexeerd", bron(exp))
					errors[#errors+1] = fout
					returntype = X'iets'
				else
					returntype = functype[n+1]
				end

			else

				local anyfunc = X('→', 'iets', 'iets')
				--moetzijn(functype, anyfunc, arg0(exp))

				if fn(functype) ~= '→' then
					returntype = X'iets'

				else
					--print('FUNCTYPE', deparse(functype))
					--print('ARGTYPE', deparse(argtype))
					moetzijn(arg0(functype), argtype, exp)

					returntype = arg1(functype)
				end

				--[[
				local fout = typifyfout(exp.loc or nergens,
					"{code}: ongeldig functieargument {exp} voor {exp}",
					bron(exp), argtype, functype
				)
				errors[#errors+1] = fout
				--error(C(functype))
				--returntype = typegraph:maaktype(X'fout')
				returntype = X'iets'
				]]

			end

			types[hash(exp)] = returntype

		elseif fn(exp) == '→' then
			local f = arg0(exp)
			local a = arg1(exp)

			local F = hash(f)
			local A = hash(a)

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
			--types[hash(exp)] = types[hash(exp)] or copy(arg1(std.functie))
			--moetzijn(types[hash(exp)], ftype, exp)
			types[hash(exp)] = ftype

		elseif fn(exp) == ':' then
			local doel,type = arg0(exp), arg1(exp)
			local type = typegraph:maaktype(type)
			--moetzijn(doel, type, arg0(exp)) -- TODO
			types[hash(exp)] = symbol.bit
			types[fn(exp)] = symbol.bit
 
		elseif ez then
			types[hash(exp)] = ez
			--moetzijn(types[hash(e

		-- standaardtypes
		elseif std[fn(exp)] then
			local stdtype = clone(std[fn(exp)])
			--local argtype = types[hash(arg(exp))]
			local argtype = types[hash(arg(exp))]
			local inn, uit = arg0(stdtype), arg1(stdtype)

			-- typify arg
			types[hash(exp.a)] = types[hash(exp.a)] or inn
			--print('ARGTYPE voor', deparse(argtype), deparse(inn), deparse(exp.a))
			local sub = exp.a
			if not sub then
				sub = X('argument van '..deparse(exp))
				sub.loc = exp.loc
			end
			moetzijn(argtype, inn, sub)

			-- typify exp
			--types[hash(exp.a)] = argtype
			types[hash(exp)] = uit

		else
			local m = hash(exp)
			if isvar(m) then
				error'OK'
			end
			types[m] = types[m] or X'iets'

		end

	end

	typifyrec(exp)

	--do return types[hash(exp)], errors, types end

	-- is alles getypifyd?
	for hash,exps in pairs(perhash) do
		if false and (not types[hash] or _G.hash(types[hash]) == 'iets')
				and not std[hash]
				and not typegraph.types[hash]
				then
				--and hash:sub(1,1) ~= ',' then
			local exp = exps[1]
			local fout = typifyfout(exp.loc or nergens,
				"cannot determine type of {code}",
				isobj(exp) and deparse(exp) or locsub(exp.code, exp.loc)
			)
			errors[#errors+1] = fout
		end
	end

	if verbozeTypes then
		print '# Eindtypes'
		for hash,type in spairs(_types or types) do
			print('EINDTYPE', type.var, hash, deparse(type))
		end
	end

	if verbozeTypes then
		types = _types or types
	end

	return types[hash(exp)], errors, types
end

