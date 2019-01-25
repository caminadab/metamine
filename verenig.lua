require 'exp'
require 'util'

-- fn = (n:tekst,p:exp[]) : exp
-- atoom: term
-- exp: fn(*) | atoom
-- eqs: (a:exp,b:exp){}
-- ass: naam → term
-- verenig: eqs → ass
function verenig(eqs,isconstant)
	local isconstant = isconstant or tonumber
	print()
	local beter = true
	local uit = {}
	repeat
		print('NU',eqs)
		beter = false
		for eq in pairs(eqs) do
			local L,R = eq[1],eq[2]
			-- verwijder
			if L == R then
				print('verwijder',eq,eq.l,eq.r)
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
					print('  +',eq)
				end
				beter = true
				break
			end

			-- conflict
			if isfn(eq[1]) and (L.fn ~= R.fn
					or #eq[1] ~= #eq[2]) then
				print('conflict',eq)
				return false
			end
			if isconstant(L) and isconstant(R) and R ~= L then
				print('conflict',eq)
				return false
			end

			-- verwissel
			if isfn(L) and isatoom(R) then
				print('verwissel',eq)
				eq[2],eq[1] = eq[1],eq[2]
				beter = true
				break
			end

			-- verifieer
			if isatoom(L) then
				local x,t = L,R
				local v = vars(t,tonumber)
				if v[x] then
					print('verifeer',x..' in vars( '..tostring(t)..' )')
					return false
				end
			end
				
			-- elimineer
			if isatoom(L) then
				print('elimineer',eq)
				local x,t = L,R
				uit[x] = t
				print('  UIT',tostring(x)..' -> '..tostring(t))
				local vers = set()
				for eq in pairs(eqs) do
					print('  substitueer',eq,tostring(x)..' := '..tostring(t))
					local eq = substitueer(eq,x,t)
					vers[eq] = true
				end
				eqs = vers
				beter = true
				break
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

	-- sin(2) ~= cos(2)
	local a = maakfn('sin','2')
	local b = maakfn('cos','2')
	local s = set(maakeq(a,b))
	assert(verenig(s) == false)

	-- recursief
	local fn = maakfn('sin', 'x')
	local s = set(maakeq('x',fn))
	print(s)
	assert(verenig(s) == false)

	-- a > 0:  a := (_ > 0) ⇒ a)

	-- fout
	local a = maakeq('x', '2')
	local b = maakeq('x', '3')
	local s = set(a,b)
	assert(verenig(s) == false)

end
