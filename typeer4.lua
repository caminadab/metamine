require 'typegraaf'
require 'ontleed'
require 'symbool'
require 'fout'

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
-- (en vul constraints)
local function ziektype(exp, types, cons, typegraaf)
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

	-- (a → b)(a) = b
	-- TA = (a → b)(a)
	-- TB = b
	-- FNA = (a → b)
	-- ARGA = a
	if fn(exp) == '_' then
		local f,a = exp.a[1], exp.a[2]
		local tf,ta = types[moes(f)], types[moes(a)]

		-- compound functietype
		if isfn(tf) and tf.a[1] and tf.a[2] and ta then
			if tf.a[1] and moes(ta) ~= 'iets' and moes(tf.a[1]) ~= 'iets' then
				if moes(ta) ~= moes(tf.a[1]) then
					cons[#cons+1] = X(':', a, tf.a[1])
					--print('constraint', combineer(cons[#cons]))
				end
			end
			--assert(tf.a[2])
			return tf.a[2]
		end

	elseif fn(exp) == '→' then
		local a,b = exp.a[1], exp.a[2]
		local ta,tb = types[moes(a)], types[moes(b)]
		if ta and tb then
			return X('→', ta, tb)
		end
		

	-- (ℝ → ℕ) ∘ (ℕ → ℝ) :  ℝ → ℝ
	elseif fn(exp) == '∘' then
		local a,b = exp.a[1], exp.a[2]
		local ta,tb = types[moes(a)], types[moes(b)]
		if ta and tb then

			--if ta.a[2], tb.a[1] then
			--	local imm = typegraaf
			cons[#cons+1] = X(':', a, X('→', ta.a[2], tb.a[1]))
			--cons[#cons+1] = X(':', b, X('→', tb.a[1], ta.a[2]))

			--local immuit = ta.a[2]
			--local immin = tb.a[1]
			--if immuit and immin then

			print('cons', combineer(cons[#cons]))
			return X('→', ta.a[1], tb.a[2])

		elseif ta then
			cons[#cons+1] = X('=', ta.a[2], ta.a[1])

		else
			--print("JOECHEI", combineer(exp))
			todo[#todo+1] = exp
		end
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
		assert(type)
		if types[moes(exp)] then
			-- oude
			local moet = types[moes(exp)]

			-- nieuwe info!
			if moet and moes(type) == moes(moet) then
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
		assert(permoes[moes(exp)], moes(exp))
		for i,alt in ipairs(permoes[moes(exp)]) do
			--print('her-eval', combineer(alt.super), alt.super and loctekst(alt.super.loc))
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

			-- constraints
			if fn(exp) == '=' then
				cons[#cons+1] = exp
			elseif fn(exp) == '∘' then
				--cons[#cons+1] = exp
				--;error'OK'
			end

			-- recurseer
			for k,sub in subs(exp) do
				rec(sub)
			end
		end
		rec(exp)
	end

	-- eztypes
	makkelijk(exp)

	-- 
	moeilijk(exp)

	-- itereren
	local it = 1
	local maxit = 10
	while #cons > 0 and it <= maxit do

		-- todo's
		for i,exp in ipairs(todo) do
			--print('todo', combineer(exp))
			local ziek = ziektype(exp, types, cons)
			if ziek then
				--print('ziek', combineer(ziek))
				typegraaf:link(ziek)
				weestype(exp, ziek)
			end
		end

		local ncons = {}

		-- constraints
		for i,con in ipairs(cons) do
			local a, b = con.a[1], con.a[2]
			local ta, tb = types[moes(a)], types[moes(b)]
			local type

			if fn(con) == ':' then
				weestype(con.a[1], con.a[2])
			else

			if ta and tb then
				local samen = typegraaf:intersectie(ta, tb)
				if samen then
					weestype(a, samen)
					weestype(b, samen)
				else
					local exp = a
					local fout = typeerfout(exp.loc or nergens,
						"{code} moet {exp} zijn maar moet ook {exp} zijn",
						bron(exp),
						ta, tb
					)
					fouten[#fouten+1] = fout
				end
			elseif ta then
				weestype(b, ta)
			elseif tb then
				weestype(a, tb)
			else
				--ncons[#ncons+1] = con
			end
		
			end

			ncons[#ncons+1] = con
			it = it + 1
		end

		cons = ncons
	end

	--[[
	if it > 2 then
		local fout = typeerfout(nergens, "types te complex")
		fouten[#fouten+1] = fout
	end
	]]

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
		print()
	end

	return types, fouten
end
