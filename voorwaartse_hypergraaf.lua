require 'voorwaartse_acyclische_hypergraaf'

local function pijl2tekst(pijl)
	local r = {}
	for bron in pairs(pijl.van) do
		r[#r+1] = bron
	end
	table.sort(r)
	return table.concat(r, ' ') .. ' -> ' .. pijl.naar
end

local function tekst(graaf)
	if not next(graaf.pijlen) then
		return '<lege graaf>'
	end
	local p = {}
	for pijl in pairs(graaf.pijlen) do
		p[#p+1] = pijl2tekst(pijl)
	end
	table.sort(p)
	return table.concat(p, '\n')
end

local function sorteer_itereer(hgraaf, onbekend, stroom)
end


-- bedenk alle hyperroutes door hypergraaf
local function sorteer(hgraaf, van, naar)
	local print = function () end
	local onbekend = {[naar]=true}
	local stroom = voorwaartse_acyclische_hypergraaf()
	local bekend = {}

	-- alle mogelijke opties
	local it = 999
	while next(onbekend) and it > 0 do
		it = it - 1
		local doel = next(onbekend)
		bekend[doel] = true
		onbekend[doel] = nil
		print('DOEL', doel)

		for pijl in hgraaf:naar(doel) do
			if stroom:link(pijl) then
				print('OPTIE', pijl2tekst(pijl))
				for bron in pairs(pijl.van) do
					-- wanneer proberen?
					if not bekend[bron] and not van[bron] then
						onbekend[bron] = true
					end
				end
			end
		end
	end

	return stroom
			
end

-- een voorwaartse hypergraaf is een hypergraaf waarbij elke hoek een specifiek punt als doel heefft
function voorwaartse_hypergraaf()
	return {
		pijlen = {},

		-- maak een hyperpijl
		link = function (h,pijl_of_van,naar)
			local van, pijl
			if naar then
				van = pijl_of_van
				pijl = {van=van,naar=naar}
			else
				pijl = pijl_of_van
				van = pijl.van
				naar = pijl.naar 
			end

			h.pijlen[pijl] = true
		end,

		-- hyperpijlen naar doel
		naar = function (self,doel)
			local hoek = nil
			return function()
				while next(self.pijlen, hoek) do
					local kan = next(self.pijlen, hoek)
					hoek = kan
					if kan.naar == doel then
						return kan
					end
				end
				-- klaar
				return nil
			end
		end,

		sorteer = sorteer,
		tekst = tekst,
	}
end

if true or test then
	local graaf = voorwaartse_hypergraaf()
	graaf:link({a = true}, 'b')
	assert(graaf:naar('b')().van.a)

	-- sorteer
	local graaf = voorwaartse_hypergraaf()
	graaf:link({a = true}, 'b')
	graaf:link({b = true}, 'a')
	local stroom = graaf:sorteer({a=true}, 'b')

	-- sorteer
	local graaf = voorwaartse_hypergraaf()
	graaf:link({a = true}, 'b')
	graaf:link({b = true}, 'c')
	graaf:link({c = true}, 'a')
	print('# Graaf')
	print(graaf:tekst())
	print()
	local stroom = graaf:sorteer({a=true}, 'c')
	print('# Stroom')
	print(stroom:tekst())
	--assert(next(stroom.pijlen).van.a)

end
