require 'typegraaf'
require 'ontleed'
require 'symbool'
require 'func'
require 'fout'
require 'exp'

local obj2sym = {
	[','] = symbool.tupel,
	['[]'] = symbool.lijst,
	['{}'] = symbool.set,
	['[]u'] = symbool.tekst,
}

local stdbron = ontleed(file('bieb/std.code'), 'bieb/std.code')
local supers = {}
local std = {}

for i,feit in ipairs(stdbron.a) do
	if fn(feit) == ':' then
		local t,s = arg0(feit), arg1(feit)
		supers[t] = s
		std[moes(t)] = s
	end
end

function linkbieb(typegraaf)
	for t,s in pairs(supers) do
		typegraaf:maaktype(t, s)
	end
	return typegraaf
end

-- makkelijke types (getallen & standaardatomen)
local function eztypeer(exp)
	if isatoom(exp) then
		if tonumber(exp.v) then
			if exp.v % 1 == 0 then
				return kopieer(symbool.int)
			else
				return kopieer(symbool.getal)
			end
		elseif std[moes(exp)] then
			return kopieer(std[moes(exp)])
		end
	elseif isobj(exp) then
		return obj2sym[obj(exp)]
	end
end

-- exp → type, fouten
function typeer(exp)
	local typegraaf = linkbieb(maaktypegraaf())
	local types = {} -- moes → type
	local permoes = permoes(exp) -- moes → moezen
	local fouten = {}
	local maakvar = maakvars()

	-- track
	if false then
	local _types = {}
	setmetatable(types, {
		__index = function(t,k) return _types[k] end;
		__newindex = function(t,k,v) v.var = v.var or maakvar(); print('Typeer', k, combineer(v), v.var); _types[k] = v end;
	})
	end

	-- ta := ta ∩ tb
	function moetzijn(ta, tb, exp)
		assert(ta)
		assert(tb)

		--if ta == tb then return ta end

		ta.var = ta.var or maakvar()

		local intersectie,fout = typegraaf:intersectie(ta, tb, exp)

		if not intersectie then
			fouten[#fouten+1] = fout
		elseif intersectie then
			--ta = intersectie
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
				t[i] = t[i] or subtype
			end
			types[m] = t

		elseif obj(exp) == '[]' then
			local lijsttype = X'iets'
			for i,sub in ipairs(exp) do
				local subtype = assert(types[moes(sub)], 'geen type voor kind '..moes(sub))
				lijsttype = moetzijn(lijsttype, subtype, sub)
				types[moes(sub)] = lijsttype
			end
			local type = typegraaf:maaktype(X('lijst', lijsttype))
			if atoom(lijsttype) == 'iets' then
				assign(type, X'lijst')
			end
			types[moes(exp)] = type

		elseif fn(exp) == '=' or fn(exp) == ':=' then
			local A = moes(arg0(exp))
			local B = moes(arg1(exp))
			assert(types[A])
			assert(types[B])
			-- verandert types[A] -- bewust!! dit voorkomt substitutie
			local T = moetzijn(types[A], types[B], arg0(exp))
			types[A] = T
			types[B] = T
			types[moes(exp)] = symbool.bit
			types[moes(arg(exp))] = typegraaf:maaktype(X(',', T, T))

		elseif fn(exp) == '⋀' then
			types[moes(exp)] = symbool.bit

		elseif fn(exp) == '⇒' then
			local A = types[moes(arg0(exp))]
			local B = types[moes(arg1(exp))]

			moetzijn(A, symbool.iets, arg0(exp)) -- TODO bit
			types[moes(exp)] = B

		elseif fn(exp) == "'" then
			local A = types[moes(exp.a)]
			types[moes(exp)] = A

		-- compositie
		elseif fn(exp) == '∘' then
			local A = types[moes(arg0(exp))]
			local B = types[moes(arg1(exp))]
			local anyfunc = X('→', 'iets', 'iets')

			moetzijn(A, anyfunc, arg0(exp))
			moetzijn(B, anyfunc, arg1(exp))

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

			local inter = moetzijn(uitA, inB, exp)
			--assign(A.a[2], inter)
			--assign(B.a[1], inter)
			A.a[2] = inter
			B.a[1] = inter

			types[moes(exp)] = compositie

		---------- linq

		-- vouw: lijst(A), (A,A → B) → lijst(B)
		elseif fn(exp) == '_' and atoom(arg0(exp)) == 'vouw' then
			local expargs = types[moes(arg1(exp))]
			--print('expargs1', combineer(expargs))
			local anya = X'iets'
			local anyb = X'iets'
			local lijsta = X('lijst', anya)
			local lijstb = X('lijst', anyb)
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
			lijst.a = moetzijn(arg(lijst), funcargs[1], exp)
			--print('HIER')
			--print(combineer(funcargs[1]))
			--print(combineer(funcargs[2]))
			--print(combineer(lijst.a))
			funcargs[1] = moetzijn(funcargs[1], lijst.a, exp)
			funcargs[2] = moetzijn(funcargs[2], funcargs[1], exp)
			moetzijn(arg(lijsta), anya, exp)
			--moetzijn(arg(lijstb), anyb, exp)

			-- A,A → B  ⇒ arg₀ = arg₁ 
			--moetzijn(arg0(anyfunc)[1], arg0(anyfunc)[2], exp)

			types['vouw'] = X'functie'
			types[moes(exp)] = anyb

		-- a _ b ⇒ ((X→Y) _ X) : Y
		elseif fn(exp) == '_' then
			local functype = types[moes(arg0(exp))]
			local argtype = types[moes(arg1(exp))]
			assert(functype)
			assert(argtype)

			local anyfunc = typegraaf:maaktype(X('→', 'iets', 'iets'))
			local functype = moetzijn(functype, anyfunc, exp.a)
			local X = moetzijn(argtype, arg0(functype), exp.a) -- TODO
			functype.a[1] = X
			local Y = arg1(functype)

			types[moes(exp)] = Y

		elseif fn(exp) == '→' then
			local f = arg0(exp)
			local a = arg1(exp)
			local F = moes(f)
			local A = moes(a)

			types[F] = types[F] or X'iets'
			types[A] = types[A] or X'iets'

			-- tf : A → B
			-- tg : B → C
			local tf = types[F]
			local ta = types[A]
			
			-- a → b
			local ftype = X('→', tf, ta)
			-- TODO
			--types[moes(exp)] = types[moes(exp)] or kopieer(arg1(std.functie))
			--moetzijn(types[moes(exp)], ftype, exp)
			types[moes(exp)] = ftype


		elseif ez then
			types[moes(exp)] = ez

		-- standaardtypes
		elseif std[fn(exp)] then
			local stdtype = kopieer(std[fn(exp)])
			local argtype = types[moes(exp.a)]
			local inn, uit = arg0(stdtype), arg1(stdtype)

			-- typeer arg
			--types[moes(exp.a)] = types[moes(exp.a)] or inn
			--print('ARGTYPE voor', combineer(argtype), combineer(inn), combineer(exp.a))
			moetzijn(argtype, inn, exp.a)
			--print('ARGTYPE na', combineer(argtype))

			-- typeer exp
			types[moes(exp)] = uit

		else
			local m = moes(exp)
			types[m] = types[m] or X'iets'
		end

	end

	typeerrec(exp)

	--do return types[moes(exp)], fouten, types end

	-- is alles getypeerd?
	for moes,exps in pairs(permoes) do
		if (not types[moes] or _G.moes(types[moes]) == 'iets')
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
		print 'moes : type'
		for moes,type in pairs(types) do
			print(type.var, moes, combineer(type))
		end
	end

	return types[moes(exp)], fouten, types
end

