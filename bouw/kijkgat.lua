require 'exp'
require 'symbool'
local insert = table.insert

--[[
KLAAR
c = a + b
	c = a
	c += b

MISS
x := (=>)(c, d, a)
	x := a
	t := (c = 0)
	x ?= (t => d)

NOG
c = a + 1
	c ++

c = a / b
d = a mod b
	t = a
	t,s /= b
	c = t
	d = s

c = a / b
	t = a
	t /= b
	c = t

c = a mod b
	t = a
	t,s /= b
	c = s

]]

function kijkgat(blok, maakvar)
	local maakvar = maakvar or maakvars()
	for i=#blok,1,-1 do
		local stat = blok[i]
		local naam,exp = stat[1],stat[2]
		--print(stat and exp2string(exp))
		local op = fn(exp)

		if #exp == 1 and op == '-' then
			local t = naam
			blok[i] = X(':=', tostring(t), 0)
			insert(blok, i+1, X('-=', t, exp[1]))

		-- a /= b
		-- a %= b
		elseif #exp == 2 and op == '+' or op == '-' or op == '*' or op == '/' or op == '^' or op == 'mod' or op == '||' or op == 'wortel' then
			-- tijdelijk
			--local t = maakvar()
			local t = naam
			-- t := arg0
			local ruimte = {fn=sym.ass, X(t), exp[1]}
			-- t *= arg1
			blok[i] = {fn=X(op..'='), X(t), exp[2]}
			insert(blok, i, ruimte)
		end
	end
	-- dubbele eruit
	local al = {}
	return blok
end

if test then
	require 'ontleed'

	local blok = ontleed 'a := b + c'
	assert(expmoes(kijkgat(blok)) == 'EN(:=(A b) +=(A c))', expmoes(kijkgat(blok)))

	local blok = ontleed 'a := b * c'
	assert(expmoes(kijkgat(blok)) == 'EN(:=(A b) *=(A c))', expmoes(kijkgat(blok)))
end
