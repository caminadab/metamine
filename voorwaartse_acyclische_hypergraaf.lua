-- is er, zonder alle pijlen te vervullen, een route van bron naar doel mogelijk?
-- zoekt achterstevoren
local function bereikbaar_disj(graaf, van, naar)
	local print = function () end
	print()
	print('# start')
	print(graaf:tekst())

	print(van..' ?-> '..naar)
	local nieuw = {naar}
	local klaar = {}
	local bereikbaar = {}

	while #nieuw > 0 do
		local punt = table.remove(nieuw, #nieuw)
		print('proberen', punt)
		klaar[punt] = true
		for pijl in graaf:naar(punt) do
			for bron0 in pairs(pijl.van) do
				-- route van "naar" naar "van" gevonden!
				print('gevonden',bron0..' -> '..naar, van, bron0 == van)
				if bereikbaar[bron0] or van[bron0] or bron0 == van then
					print('BEREIKBAAR')
					return true
				end
				if not klaar[bron0] then
					klaar[bron0] = true
					nieuw[#nieuw+1] = bron0
					print('todo', bron0)
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

function link(vahgraaf, pijl_of_van, naar)
	local van, pijl
	if naar then
		van = pijl_of_van
		pijl = {van=van,naar=naar}
	else
		pijl = pijl_of_van
		van = pijl.van
		naar = pijl.naar 
	end

	-- mag geen route van "naar" naar "van"
	for bron in pairs(van) do
		-- bron bereikbaar vanaf einde?
		if vahgraaf:bereikbaar_disj(naar, bron) then
			return false
		end
	end

	vahgraaf.pijlen[pijl] = true
	return true
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
		tekst = tekst,
	}
end

if test or true then
	-- bereikbaar disj
	local graaf = voorwaartse_acyclische_hypergraaf()
	graaf:punt('a')
	graaf:punt('b')
	assert(not graaf:bereikbaar_disj('a', 'b'))
	graaf:link({a=true},'b')
	assert(graaf:bereikbaar_disj('a', 'b'))

	-- link
	local graaf = voorwaartse_acyclische_hypergraaf()
	graaf:punt('a')
	graaf:punt('b')
	assert(graaf:link({a=true}, 'b'))
	assert(not graaf:link({b=true}, 'a'))

	-- superlink
	-- a->b  a,b->c
	local graaf = voorwaartse_acyclische_hypergraaf()
	graaf:punt('a')
	graaf:punt('b')
	graaf:punt('c')
	assert(graaf:link({a=true}, 'b'))
	assert(graaf:link({a=true,b=true}, 'c'))
	-- b->a mag niet
	assert(not graaf:link({b=true}, 'a'))
	-- a,c->b mag niet
	assert(not graaf:link({a=true,c=true}, 'b'))
	
end
