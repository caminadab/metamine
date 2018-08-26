-- een voorwaartse hypergraaf is een hypergraaf waarbij elke hoek een specifiek punt als doel heefft
function voorwaartse_hypergraaf()
	return {
		hoeken = {},
		link = function (h,van,naar)
			h.hoeken[{van,naar,van=van,naar=naar}] = true
		end,
		naar = function (h,bron)
			local hoek = nil
			return function()
				while next(hoeken,hoeken) do
					local kan = next(hoeken,hoek)
					hoek = kan
					if kan.naar == bron then
						return kan
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
	hgraaf:link('a', {'b'})
end
