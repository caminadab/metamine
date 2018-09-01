-- is er, zonder alle pijlen te vervullen, een route van bron naar doel mogelijk?
local function bereikbaar_disj(graaf, van, naar)
	local nieuw = {van}
	local klaar = {}
	local bereikbaar = {}

	while #nieuw > 0 do
		local punt = table.remove(nieuw, #nieuw)
		print('PUNT', punt)
		klaar[punt] = true
		for pijl in graaf:naar(punt) do
			for bron0 in pairs(pijl.van) do
				-- route van "naar" naar "van" gevonden!
				if bereikbaar[bron0] or bron0 == naar then
					return true
				end
				if not klaar[bron0] then
					klaar[bron0] = true
					nieuw[#nieuw+1] = bron0
				end
			end
		end
	end

	return false
end

-- hyperpijlen naar doel
local function naar(self,doel)
	local pijl = nil
	return function()
		while next(self.pijlen, pijl) do
			local kan = next(self.pijlen, pijl)
			pijl = kan
			if kan.naar == doel then
				return kan
			end
		end
		-- klaar
		return nil
	end
end

function link(vahgraaf, pijl_of_van, naar)
	local van
	if naar then
		van = pijl_of_van
	else
		local pijl = pijl_of_van
		van = pijl.van
		naar = pijl.naar 
	end

	-- mag geen route van "naar" naar "van"
	if not vahgraaf:bereikbaar_disj(van, naar) then
		local pijl = {van=van,naar=naar}
		vahgraaf.pijlen[pijl] = true
		return true
	else
		return false
	end
end

function voorwaartse_acyclische_hypergraaf()
	return {
		punten = {},
		pijlen = {},

		punt = function (vahgraaf, punt)
			vahgraaf.punten[punt] = true
		end,
		naar = naar,
		link = link,
		bereikbaar_disj = bereikbaar_disj,
	}
end

if test or true then
	local graaf = voorwaartse_acyclische_hypergraaf()
	graaf:punt('a')
	graaf:punt('b')
	assert(graaf:link({a=true}, 'b'))
	assert(not graaf:link({b=true}, 'a'))
end
