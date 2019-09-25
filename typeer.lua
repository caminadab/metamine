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
		local t,s = a(feit), b(feit)
		supers[t] = s
		std[moes(t)] = s
	end
end

function linkbieb(typegraaf)
	for t,s in pairs(supers) do
		typegraaf:link(t, s)
	end
	return typegraaf
end

-- makkelijk type (int, atoomfunc)
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

	function moetzijn(ta, tb, exp)
		if not ta then
			if not tb then
				ta = X'iets'
			else
				return tb
			end
		end
		ta.var = ta.var or maakvar()
		local tb = tb or ta

		local intersectie = typegraaf:intersectie(ta, tb)

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
		--assign(tb, intersectie)
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
				local subtype = assert(types[moes(sub)])
				t[i] = t[i] or subtype
			end
			types[m] = t
			print('Tuple Type', combineer(t))

		elseif fn(exp) == '=' then
			local A = moes(a(exp))
			local B = moes(b(exp))
			-- verandert types[A] -- bewust!! dit voorkomt substitutie
			types[A] = types[A] or X'iets'
			local T = moetzijn(types[A], types[B], a(exp))
			types[A] = T
			types[B] = T
			types[moes(exp)] = symbool.bit

		elseif fn(exp) == '⋀' then
			types[moes(exp)] = symbool.bit

		elseif fn(exp) == '∘' then
			local f = a(exp)
			local g = b(exp)
			local F = moes(f)
			local G = moes(g)
			types[F] = types[F] or kopieer(a(a(std['∘'])))
			types[G] = types[G] or kopieer(b(a(std['∘'])))

			-- tf : A → B
			-- tg : B → C
			local tf = types[F]
			local tg = types[G]

			local compositie = X('→', a(tf), b(tg))
			types[moes(exp)] = types[moes(exp)] or kopieer(b(std['∘']))

			moetzijn(b(tf), a(tg), exp)
			moetzijn(types[moes(exp)], compositie, exp)

		elseif fn(exp) == '→' then
			local f = a(exp)
			local a = b(exp)
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
			moetzijn(ez, types[moes(exp)], exp)
			types[moes(exp)] = ez

		-- standaardtypes
		elseif std[fn(exp)] then
			local stdtype = std[fn(exp)]
			local argtype = types[moes(exp.a)]
			local inn, uit = a(stdtype), b(stdtype)

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

