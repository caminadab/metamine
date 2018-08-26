-- een voorwaartse hypergraaf is een hypergraaf waarbij elke hoek een specifiek punt als doel heefft
function voorwaartse_hypergraaf()
	return {
		hoeken = {},
		link = function (h,van,naar)
			h.hoeken[{van,naar,van=van,naar=naar}] = true
		end,
		naar = function (self,bron)
			local hoek = nil
			return function()
				while next(self.hoeken, hoek) do
					local kan = next(self.hoeken, hoek)
					hoek = kan
					if kan.naar == bron then
						return kan.van
					end
				end
				-- klaar
				return nil
			end
		end,
	}
end

if test then
	local hgraaf = voorwaartse_hypergraaf()
	hgraaf:link({a = true}, 'b')

	assert(hgraaf:naar('b')().a, 'a niet gedefinieerd')
end
