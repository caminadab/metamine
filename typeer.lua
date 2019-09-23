require 'typegraaf'
require 'ontleed'
require 'symbool'

local std = ontleed(file('bieb/std.code'), 'bieb/std.code')

local obj2sym = {
	[','] = symbool.tupel,
	['[]'] = symbool.lijst,
	['{}'] = symbool.set,
	['[]u'] = symbool.tekst,
}

function linkbieb(typegraaf)
	for i,feit in ipairs(std.a) do
		--print('FEIT', combineer(feit))
		if fn(feit) == ':' then
			local type, super = feit.a[1],feit.a[2]
			typegraaf:link(type, super)
			std[moes(feit.a[1])] = super
		end
	end
	return typegraaf
end

local typegraaf
function eztype(exp)
	if isatoom(exp) then
		if tonumber(exp.v) then
			if exp.v % 1 == 0 then
				return symbool.int
			else
				return symbool.getal
			end
		elseif std[exp.v] then
			return std[exp.v]
		end
	end
	if isobj(exp) then
		return obj2sym[obj(exp)]
	end
end

-- vind gave types
local function ziektype(exp, types)
	if isobj(exp) and obj(exp) == ',' then
		local T = {o = exp.o}
		for i,sub in ipairs(exp) do
			local zt = types[moes(sub)]
			if not zt then
				T = nil
				break
			end
			T[i] = zt
		end
		return T
	end
end

--[[
zelfde moes = zelfde type
eerst ez types & cons
dan herhaal:
	pas constraints toe
	verwerk type ass
]]
function typeer(exp)
	local types = {}
	local todo = {} -- moezen
	local cons = {} -- type constraints! (lijst equalities)
	
	local permoes = permoes(exp)
	local fouten = {}

	typegraaf = maaktypegraaf()
	linkbieb(typegraaf)

	function weestype(exp, type)
		if types[moes(exp)] then
			-- oude
			local moet = types[moes(exp)]

			-- nieuwe info!
			if moes(type) == moes(moet) then
				return

			-- nieuwe info!
			elseif typegraaf:issubtype(type, moet) then
				--todo[#todo+1] = X(':', exp, type)
				--print(combineer(type) .. ' :: ' .. combineer(moet))
				todo[#todo+1] = exp

			-- voegt niets nieuws toe
			elseif typegraaf:issubtype(moet, type) then
				return

			else
				local fout = typeerfout(exp.loc,
					"{code} is {exp} maar moet {exp} zijn",
					bron(exp), type, moet
				)
				-- meer fouten krijgen
				--type = typegraaf:unie(type, moet)
				type = moet
				fouten[#fouten+1] = fout
			end
		end

		-- DESTRUCTUREER KOMMA's
		if type and obj(type) == ',' and obj(exp) == ',' then
			for i,sub in ipairs(exp) do
				weestype(sub, type[i])
			end
		end

		types[moes(exp)] = type
		if verbozeTypes then
			print('typeer', combineer(exp), combineer(type))
		end

		-- her-evalueer de supers
		for i,alt in ipairs(permoes[moes(exp)]) do
			todo[#todo+1] = alt.super
			--print('todo', combineer(todo[#todo]))
		end
	end

	function makkelijk(exp)
		function rec(exp)
			-- makkelijke atomen
			local type = eztype(exp)
			if type then
				weestype(exp, type)
			end

			-- standaardfuncties
			if isfn(exp) and std[fn(exp)] then
				local type = std[fn(exp)]
				weestype(exp.a, type.a[1]) -- arg
				weestype(exp, type.a[2]) -- res
			end

			-- recurseer
			for k,sub in subs(exp) do
				rec(sub)
			end
		end
		rec(exp)
	end
	makkelijk(exp)

	-- todo's
	for i,exp in ipairs(todo) do
		--print('todo', combineer(exp))
		local ziek = ziektype(exp, types)
		if ziek then
			--print('ziek', combineer(ziek))
			typegraaf:link(ziek)
			weestype(exp, ziek)
		end
	end

	-- is alles getypeerd?
	for moes,exps in pairs(permoes) do
		if (not types[moes] or _G.moes(types[moes]) == 'iets') and not std[moes] and not typegraaf.types[moes] then
			local exp = exps[1]
			local fout = typeerfout(exp.loc or nergens,
				"kon type niet bepalen van {code}",
				isobj(exp) and combineer(exp) or locsub(exp.code, exp.loc)
			)
			fouten[#fouten+1] = fout
		end
	end

	if verbozeTypegraaf then
		print()
		print('# TYPEGRAAF')
		print(typegraaf)
	end

	return types, fouten
end
