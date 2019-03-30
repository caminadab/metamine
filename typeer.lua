require 'exp'

--[[
teken^int ⊂ (int → teken)
tekst = teken^int
]]
function typeer(exp)
	local t = {}
	-- type = boom | set van types
	--   gebruikt set van types
	-- t = exp → type
	for v in boompairs(exp) do
		if isatoom(v) then
			if tonumber(v.v) and math.modf(tonumber(v.v), 1) == 0 then
				v.is = {int = true, getal = true}
				v.val = tonumber(v.v)
			elseif tonumber(v.v) then
				v.is = {getal = true}
				v.val = tonumber(v.v)
			elseif v.v == "[]" then
				
