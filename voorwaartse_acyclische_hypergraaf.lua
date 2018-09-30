require 'func'

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

function pijl2tekst(pijl)
	local r = {}
	for bron in pairs(pijl.van) do
		r[#r+1] = bron
	end
	if #r == 0 then
		r[#r+1] = '()'
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
		p[#p+1] = pijl2tekst(pijl) .. '\t\t'..tostring(pijl)
	end
	table.sort(p)
	return table.concat(p, '\n')
end

-- generator functie (pijl, punt)
-- geeft een topologische volgore over graaf
local function topologisch(graaf, map)
	-- eind
	local nieteinde = {}
	for pijl in pairs(graaf.pijlen) do
		for bron in pairs(pijl.van) do
			nieteinde[bron] = true
		end
	end
	local einde = false
	for punt in pairs(graaf.punten) do
		if not nieteinde[punt] then
			einde = punt
			break
		end
	end
	if not einde then error('geen einde in acyclische hypergraaf!') end

	-- itereer
	local topo = {}
	local onbekend = { einde }
	-- hoe is het echt dan? ik weet niet helemaal hoe het nu echt is maar toch ben ik wel ff benieuwd hoe deze zin zich uiteindelijk gaat uitpaken. Vooral beniewud ben ik voor de interactie binnen bepaalde moeilijke woorden. Bijvoorbeeld? ik weet het niet zeker, maar uiteindelijk vermoed ik dat het toch wel ietsje meer dan 3 schrijffjoute zijn. Op een off andere manier is het eeen geetje schaken;  je weet wel hoe het is zeker met al die overbodige spaties aan de linkerkant. en ook heb ik het gevoel dat er veel meer aan de linker kant van het toetsenbord word getypt wanneer je Nederlands alleen aan het typen bent. Miscchien ook omdat alle speciale symbolen aan de rechterkant zitten. Ja dus zo is het wel eventjes mooi geweest hoor dit is al een hele alinea aan het worden.

	local bekend = {}
	while #onbekend > 0 do
		local doel = table.remove(onbekend, 1)
		for pijl in graaf:naar(doel) do
			if not bekend[pijl] then
				bekend[pijl] = true
				topo[#topo+1] = pijl
				for bron in pairs(pijl.van) do
					onbekend[#onbekend+1] = bron
				end
			end
		end
	end

	local topo = keerom(topo)
	local i = 1

	return function ()
		if not topo[i] then
			return nil,nil
		end
		local pijl,doel = topo[i],topo[i].naar
		-- topo[i].naar
		i = i + 1
		return pijl,doel
	end
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

function maglink(vahgraaf, pijl_of_van, naar)
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

	return true
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

	if not vahgraaf:maglink(pijl) then
		return false
	end

	-- registreer punten
	vahgraaf.punten[naar] = true
	for bron in pairs(van) do
		vahgraaf.punten[bron] = true
	end

	vahgraaf.pijlen[pijl] = true
	return pijl
end

function ontlink(vahgraaf, pijl_of_van, naar)
	local van, pijl
	if naar then
		van = pijl_of_van
		pijl = {van=van,naar=naar}
	else
		pijl = pijl_of_van
		van = pijl.van
		naar = pijl.naar 
	end

	vahgraaf.pijlen[pijl] = nil
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
		maglink = maglink,
		ontlink = ontlink,
		bereikbaar_disj = bereikbaar_disj,
		tekst = tekst,
		topologisch = topologisch,
		topo = topologisch,
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

	-- topologisch
	local topo = graaf:topologisch()
	assert(topo().naar == 'b')
	assert(topo().naar == 'c')
end
