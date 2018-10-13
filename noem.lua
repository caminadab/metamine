require 'util'
require 'isoleer'
require 'symbool'
require 'voorwaartse-hypergraaf'

-- herschrijft vergelijkingen
function deduceer(feiten)
	local f = {}

	-- constanten
	for c in pairs(val(feiten)) do
		if tonumber(c) then
			f[#f+1] = {':', c, 'getal'}
		end
	end

	-- vglen herschrijven
	for i,feit in ipairs(feiten) do
		for naam in pairs(var(feit)) do
			local dfeit = isoleer(feit, naam)
			if dfeit then
				f[#f+1] = dfeit
			end
		end
	end

	-- extra toevoegen
	f[#f+1] = {':', 'getal', 'in'}
	f[#f+1] = {'=', 'uit', 'stdout'}
	f[#f+1] = {':', 'cat', 'in'}

	return f
end

-- feiten -> AFHANKELIJKHEIDSHYPERGRAAF
-- plus: pijl -> feiten
function berekenbaarheid(feiten)
	local hgraaf = voorwaartse_hypergraaf()
	local map = {}

	for i,feit in ipairs(feiten) do
		-- vergelijking?
		if isexp(feit) and feit[1] == ':' then
			local a,b = feit[2],feit[3]
			local pijl = {van = val(b), naar = a}
			-- a : getal
			map[pijl] = feit
			hgraaf:link(pijl)
		end

		if isexp(feit) and feit[1] == '=' then
			local a,b = feit[2],feit[3]

			-- a = 1 + 2
			if isvar(a) then
				local pijl = {van = val(b), naar = a}
				map[pijl] = feit
				hgraaf:link(pijl)
			end
		
			-- 1 + 2 = b
			if isvar(b) and not isvar(a) then
				local pijl = {van = val(a), naar = b}
				local feit = {feit[1],feit[3],feit[2]}
				map[pijl] = feit
				hgraaf:link(pijl)
			end

			-- (1): in -> 1
			--[[for c in pairs(val(feit)) do
				if tonumber(c) then
					local pijl = hgraaf:link(set('in'), c)
				end
			end]]

		end
	end
	return hgraaf, map
end

