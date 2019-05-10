require 'exp'
require 'symbool'
local insert = table.insert

--[[


c = a + b
	c = a
	c += b

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

function kijkgat(blok)
	local maakvar = maakvars()
	for i=1,#blok do
		local stat = blok[i]
		local exp = stat[2]
		local op = fn(exp)

		-- a /= b
		-- a %= b

		if op == '+' or op == '-' or op == '*' or op == '/' or op == 'mod' then
			-- tijdelijk
			local t = maakvar()
			local ruimte = {fn=sym.ass, X(t), exp[1]}
			blok[i] = {fn=X(op..'='), X(t), exp[2]}
			insert(blok, i, ruimte)
		end
	end
	return blok
end

if test then
	require 'ontleed'

	local blok = ontleed 'a := b + c'
	assert(expmoes(kijkgat(blok)) == 'EN(:=(A b) +=(A c))', expmoes(kijkgat(blok)))

	local blok = ontleed 'a := b * c'
	assert(expmoes(kijkgat(blok)) == 'EN(:=(A b) *=(A c))', expmoes(kijkgat(blok)))
end
