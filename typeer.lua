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
function eztypeer(exp)
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
	elseif std[fn(exp)] then
		local B = std[fn(exp)]
		return kopieer(b(B))
	elseif isobj(exp) then
		return obj2sym[obj(exp)]
	end
end

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

		if not intersectie then
			fouten[#fouten+1] = typeerfout(tb.loc,
				'{code} is {exp} maar moet {exp} zijn',
				bron(exp), kopieer(tb), kopieer(ta))
			intersectie = tb
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

		if fn(exp) == '=' then
			local A = moes(a(exp))
			local B = moes(b(exp))
			-- verandert types[A] -- bewust!! dit voorkomt substitutie
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
			types[F] = types[F] or kopieer(std['∘'])
			types[G] = types[G] or kopieer(std['∘'])

			-- tf : A → B
			-- tg : B → C
			local tf = types[F]
			local tg = types[G]

			local compositie = X('→', a(tf), b(tg))
			print('Compositie Voor  '.. combineer(compositie))
			moetzijn(b(tf), a(tg), exp)
			moetzijn(types[moes(exp)], compositie, exp)
			print('Compositie Na  '.. combineer(compositie))

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
			--error('ftype '..combineer(ftype))

			moetzijn(types[moes(exp)], ftype, exp)

		elseif ez then
			moetzijn(ez, types[moes(exp)], exp)
			types[moes(exp)] = ez

		elseif std[fn(exp)] then
			local type = std[fn(exp)]
			local f,a = a(type), b(type)

		end

	end

	typeerrec(exp)

	do return types, fouten end

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

	--for k,v in pairs(types) do
		--print(k .. ' : '.. combineer(v), '', v.var)
	--end

	return types, fouten
end

