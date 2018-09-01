require 'voorwaartse_acyclische_hypergraaf'

-- bedenk hyperroute door hypergraaf
function routeer(hgraaf, van, naar)
	local onbekend = {naar}
	local pad = voorwaartse_acyclische_hypergraaf()

	-- alternatieve routen
	for doel in pairs(onbekend) do
		for pijl in hgraaf:naar(doel) do
		end
	end
			
end

-- een voorwaartse hypergraaf is een hypergraaf waarbij elke hoek een specifiek punt als doel heefft
function voorwaartse_hypergraaf()
	return {
		pijlen = {},

		-- maak een hyperpijl
		link = function (h,pijl_of_van,naar)
			local van
			if naar then
				van = pijl_of_van
			else
				local pijl = pijl_of_van
				van = pijl.van
				naar = pijl.naar 
			end

			h.pijlen[{van,naar,van=van,naar=naar}] = true
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

		pad = routeer,
		routeer = routeer,
	}
end

if test then
	local hgraaf = voorwaartse_hypergraaf()
	hgraaf:link({a = true}, 'b')

	assert(hgraaf:naar('b')().van.a, 'a niet gedefinieerd')
end
