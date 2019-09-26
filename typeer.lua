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
	elseif false and std[fn(exp)] then
		local B = std[fn(exp)]
		return kopieer(b(B))
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

	-- ta := ta ∩ tb
	function moetzijn(ta, tb, exp)
		assert(ta)
		assert(tb)
		ta.var = ta.var or maakvar()

		local intersectie = typegraaf:intersectie(ta, tb)
		print('INTERSECTIE', combineer(ta), combineer(tb), combineer(intersectie))

		if intersectie and moes(intersectie) ~= moes(ta) then
			print('nieuwe info', combineer(exp) .. ': '.. combineer(intersectie))
		end

		if not intersectie then
			fouten[#fouten+1] = typeerfout(tb.loc,
				'{code} is {exp} maar moet {exp} zijn',
				bron(exp), kopieer(tb), kopieer(ta))
			intersectie = ta
		end

		-- TODO wrm twee
		assign(ta, intersectie)
		assign(tb, intersectie)

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

		elseif fn(exp) == '=' then
			local A = moes(arg0(exp))
			local B = moes(arg1(exp))
			-- verandert types[A] -- bewust!! dit voorkomt substitutie
			types[A] = types[A] or X'iets'
			local T = moetzijn(types[A], types[B], arg0(exp))
			types[A] = T
			types[B] = T
			types[moes(exp)] = symbool.bit

		elseif fn(exp) == '⋀' then
			types[moes(exp)] = symbool.bit

		elseif fn(exp) == '∘' then
			local A = types[moes(arg0(exp))]
			local B = types[moes(arg1(exp))]

			print('voor', combineer(A), combineer(B))
			moetzijn(A, std['→'], arg0(exp))
			moetzijn(B, std['→'], arg1(exp))
			print('na  ', combineer(A), combineer(B))
			print('was', combineer(std['→']))

			local  inA = arg0(A)
			local uitA = arg1(A)
			local  inB = arg0(B)
			local uitB = arg1(B)

			-- compo
			local compositie = X('→', inA, uitB)

			moetzijn(uitA, inB, exp)
			types[moes(exp)] = compositie

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
			--types[moes(exp)] = types[moes(exp)] or kopieer(b(std['→']))
			--moetzijn(types[moes(exp)], ftype, exp)
			types[moes(exp)] = ftype

		elseif ez then
			types[moes(exp)] = ez

		-- standaardtypes
		elseif std[fn(exp)] then
			local stdtype = std[fn(exp)]
			local argtype = types[moes(exp.a)]
			local inn, uit = arg0(stdtype), arg1(stdtype)

			-- typeer arg
			--types[moes(exp.a)] = types[moes(exp.a)] or inn
			moetzijn(argtype, inn, exp.a)

			-- typeer exp
			types[moes(exp)] = uit

		else
			local m = moes(exp)
			types[m] = types[m] or X'iets'
		end

	end

	typeerrec(exp)

	do return types[moes(exp)], fouten, types end

	-- is alles getypeerd?
	for moes,exps in pairs(permoes) do
		if (not types[moes] or _G.moes(types[moes]) == 'iets')
				and not std[moes]
				and not typegraaf.types[moes]
				and moes:sub(1,1) ~= ',' then
			local exp = exps[1]
			local fout = typeerfout(exp.loc or nergens,
				"kon type niet bepalen van {code}",
				isobj(exp) and combineer(exp) or locsub(exp.code, exp.loc)
			)
			fouten[#fouten+1] = fout
		end
	end

	return types, fouten
end

