require 'exp'
require 'util'
local print = function() end

-- fn = (n:tekst,p:exp[]) : exp
-- atoom: term
-- exp: fn(*) | atoom
-- eqs: (a:exp,b:exp){}
-- ass: naam → term
-- verenig: eqs → ass
function verenig(eqs,isinvoer)
	if A then print = _G.print end
	local isinvoer = isinvoer or tonumber
	print()
	local beter = true
	local uit = {}
	repeat
		beter = false
		for eq in pairs(eqs) do
			local L,R = eq[1],eq[2]

			-- verwijder
			if L == R then
				print('verwijder',eq)
				eqs[eq] = nil
				beter = true
				break
			end

			-- ontbind
			if isfn(L) and L.fn == R.fn then
				print('ontbind',eq)
				eqs[eq] = nil
				for i=1,#eq[1] do
					local l = L[i]
					local r = R[i]
					local eq = maakeq(l,r)
					eqs[eq] = true
					print('  dus',eq)
				end
				beter = true
				break
			end

			-- verwissel
			if (isfn(L) or isinvoer(L)) and isatoom(R) and not isinvoer(R) then
				print('verwissel',eq)
				eq[2],eq[1] = eq[1],eq[2]
				beter = true
				break
			end

			-- conflict
			if isfn(eq[1]) and (L.fn ~= R.fn or L ~= R) then
				print('conflict',eq)
				local L = tostring(toexp(L))
				local R = tostring(toexp(R))
				return false, 'verenigingsconflict voor '..eq.fn..': '..L..' ≠ '..R
			end
			if isinvoer(L) and isinvoer(R) and R ~= L then
				print('conflict',eq)
				return false, 'verenigingsconflict voor '..fn..': '..L..' ≠ '..R
			end

			-- verifieer
			if isatoom(L) then
				local x,t = L,R
				if bevat(t,x) then
					-- niets aan de hand
					--print('verifeer',tostring(t)..' bevat '..tostring(x))
					--return false, tostring(t)..' bevat '..tostring(x)
				end
			end
				
			-- elimineer
			if isatoom(L) then
				local kan = true
				for naam in pairs(var(R)) do
					if naam == L then
						if not uit[naam] then
							kan = false
						end
					end
				end

				if kan then
					print('elimineer',eq)
					local x,t = L,R
					uit[x] = t
					print('  uit',tostring(x)..' -> '..tostring(t))

					-- substitueer vergelijkingen
					local vers = set()
					for eq in pairs(eqs) do
						local eq0 = substitueer(eq,x,t)
						print('  substitueer',eq,tostring(x)..' := '..tostring(t),eq0)
						vers[eq0] = true
					end
					eqs = vers

					-- substitueer waarderingen
					local vers_uit = set()
					for naam,term in pairs(uit) do
						local term0 = substitueer(term,x,t)
						print('  substitueer',term,tostring(x)..' := '..tostring(t),term0)
						vers_uit[naam] = term0
					end
					uit = vers_uit

					beter = true
					break
				end

			end
		end
	until not beter
	print()

	return uit
end

if test then

	-- mapping
	local a = maakeq('x', '2')
	local s = set(a)
	assert(verenig(s).x == '2')

	-- makkelijk
	local aa = maakeq('a','a')
	local a = set(aa)
	assert(not next(verenig(a)))

	-- sin(2) ≠ cos(2)
	local a = maakfn('sin','2')
	local b = maakfn('cos','2')
	local s = set(maakeq(a,b))
	assert(verenig(s) == false)

	-- recursief
	local fn = maakfn('sin', 'x')
	local s = set(maakeq('x',fn))
	print(s)
	assert(verenig(s) == false, tostring(toexp(verenig(s))))

	-- a > 0:  a := (_ > 0) ⇒ a

	-- fout
	local a = maakeq('x', '2')
	local b = maakeq('x', '3')
	local s = set(a,b)
	local v,f = verenig(s)
	assert(not verenig(s))
	assert(f)

	-- fout 2
	local a = maakeq('x', '3')
	local b = maakeq('2', 'x')
	local s = set(a,b)
	local v,f = verenig(s)
	assert(not verenig(s))
	assert(f)

end
