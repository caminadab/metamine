require 'exp'
require 'stroom'

--[[
teken^int ⊂ (int → teken)
tekst = teken^int

]]

function isconstant(v)
	if isatoom(v) then
		if tonumber(v.v) and math.modf(tonumber(v.v), 1) == 0 then
			v.is = {int = true, getal = true}
			v.val = tonumber(v.v)
			return true
		elseif tonumber(v.v) then
			v.is = {getal = true}
			v.val = tonumber(v.v)
			return true
		elseif bieb[v.v] then
			v.val = bieb[v.v]
			v.is = {iets = true}
			return true
		end
	else
		local c = true
		if not isconstant(v.fn) then
			c = false
		end
		for i,v in ipairs(v) do
			if not isconstant(v) then
				c = false
			end
		end
	end
			
	return false
end

local bieb = [[
getal : iets
int : getal
ja : bit
nee : bit
(+) :  (getal, getal) → getal
(-) :  (getal, getal) → getal
(*) :  (getal, getal) → getal
(/) :  (getal, getal) → getal
(^) :  (getal, getal) → getal
(#) :  (iets^int) → int
(=>) :  bit → iets 
]]
function typeer(exp)
	local t = {}
	-- type = boom | set van types
	--   gebruikt set van types
	-- t = exp → type
	for v in boompairsdfs(exp) do
		if isconstant(v) then
			v.val = doe(v)
		end
	end
end

local bieb = ontleed(bieb)

function typeer(exp, t)
	local typegraaf = stroom()
	typegraaf:link({}, "iets")
	local typegraaf = typegraaf:kopieer()

	local types = {}
	for i,v in ipairs(bieb) do
		local symbool = v[1].v
		local type = v[2]
		types[symbool] = type
		typegraaf:link(set(type), symbool)
	end

	function maaktype(w, sup)
		typegraaf:link(set(sup), w)
		return w
	end

	for v in boompairsdfs(exp, t) do
		local T
		if tonumber(v.v) and math.modf(v.v, 1) == 0 then T = maaktype(v.v, 'int')
		elseif tonumber(v.v) then T = maaktype(v.v, 'getal')
		elseif types[v.v] then print('BIEBB') ; types[exp] = types[v.v]
		end

		types[exp] = T
	end

	print(typegraaf:tekst())
end
