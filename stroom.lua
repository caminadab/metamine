require 'func'

-- is er, zonder alle pijlen te vervullen, een route van bron naar doel mogelijk?
-- zoekt achterstevoren
local function bereikbaar_disj(graaf, van, naar)
	--print()
	--print('# start')
	--print(graaf:tekst())

	--print(tostring(van)..' ?-> '..tostring(naar))

	if type(van) ~= 'table' then
		van = {[van] = true}
	end

	local nieuw = {naar}
	local klaar = {}
	local bereikbaar = {}

	while #nieuw > 0 do
		local punt = table.remove(nieuw, #nieuw)
		--print('proberen', punt)
		klaar[punt] = true
		for pijl in graaf:naar(punt) do
			for bron0 in pairs(pijl.van) do
				-- route van "naar" naar "van" gevonden!
				--print('gevonden',tostring(bron0)..' -> '..tostring(naar), van, bron0 == van)
				if bereikbaar[bron0] or van[bron0] or bron0 == van then
					--print('BEREIKBAAR')
					return true
				end
				if not klaar[bron0] then
					klaar[bron0] = true
					nieuw[#nieuw+1] = bron0
					--print('todo', bron0)
				end
			end
		end
	end

	return false
end

function pijl2tekst(pijl)
	local r = {}
	for bron in pairs(pijl.van) do
		r[#r+1] = tostring(bron)
	end
	if #r == 0 then
		r[#r+1] = '()'
	end
	table.sort(r)
	return table.concat(r, ' ') .. ' -> ' .. tostring(pijl.naar)
end

local function tekst(graaf)
	if not next(graaf.pijlen) then
		return '<lege graaf>'
	end
	local p2 = {}
	local al = {}
	for pijl in pairs(graaf.pijlen) do
		al[pijl.naar] = true
		for bron in pairs(pijl.van) do al[bron] = true end
		p2[#p2+1] = pijl2tekst(pijl)
	end
	local p1 = {}
	for punt in pairs(graaf.punten) do
		if not al[punt] then
			table.insert(p1, tostring(punt)..'.')
		end
	end
	table.sort(p1)
	table.sort(p2)
	return table.concat(p1, '\n') .. '\n' .. table.concat(p2, '\n')
end

-- generator functie (pijl, punt)
-- geeft een topologische volgore over graaf
local function topologisch2(graaf)
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

local function kopieer(hgraaf)
	local kopie = {punten = {}, pijlen = {}}
	for k,v in pairs(hgraaf) do
		if k ~= 'punten' and k ~= 'pijlen' then
			kopie[k] = v
		end
	end
		
	for punt in pairs(hgraaf.punten) do
		kopie.punten[punt] = true
	end
	for pijl in pairs(hgraaf.pijlen) do
		kopie.pijlen[pijl] = true
	end
	return kopie
end

local function topologisch(hgraaf)
	--local print = function () end
	--TODO if isatoom(van) then van = {[van] = true} end
	local volgorde = {}
	local nieuw = {}
	local bekend = {}

	-- verzamel begin
	local van = {}
	local nietbegin = {}
	for pijl in pairs(hgraaf.pijlen) do
		-- geen lege pijl?
		if next(pijl.van) then
			nietbegin[pijl.naar] = true
		else
			nieuw[pijl] = true
		end
	end
	for punt in pairs(hgraaf.punten) do
		if not nietbegin[punt] then
			van[punt] = true
		end
	end

	for punt in pairs(van) do
		for pijl in hgraaf:van(punt) do
			nieuw[pijl] = true
		end
	end
	if not next(nieuw) then
		return false,'geen begin gevonden'
	end

	while next(nieuw) do
		local pijl = next(nieuw)
		--print('LINK?',pijl2tekst(pijl))
		nieuw[pijl] = nil

		-- alle bronnen bekend?
		local ok = true
		for bron in pairs(pijl.van) do
			if not bekend[bron] and not van[bron] then
				ok = false
				--print('  NEE: '.. bron..' is onbekend')
			end
		end

		if ok then --and not bekend[pijl] then
			volgorde[#volgorde+1] = pijl
			--print('  JA')
			bekend[pijl.naar] = true
			for pijl in hgraaf:van(pijl.naar) do
				if true or not bekend[pijl.naar] then
				--print('  GELINKT')
					nieuw[pijl] = true
				end
			end
			bekend[pijl] = true
		end

	end

	--if not bekend[naar] then
		--return false,'doel "'..naar..'" niet bereikt'
	--end
	
	-- we moeten helaas alle dubbelen uitfilteren, achterstevoren _.-._
	local al = {}
	for i=#volgorde,1,-1 do
		local naam = volgorde[i]
		if al[naam] then table.remove(volgorde,i)
		else al[naam] = true end
	end

	-- lui...
	--[[
	local i = 1
	return function ()
		i = i + 1
		return volgorde[i-1]
	end
	]]

	return volgorde
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

	-- zit hij er al in?
	for alpijl in pairs(vahgraaf.pijlen) do
		-- TODO kijk ook naar andere bronnen
		if next(alpijl.van) == next(pijl.van) and pijl.naar == alpijl.naar then
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

	if type(van) ~= 'table' then error('"van" moet set zijn maar is '..type(van)) end

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

-- iterator over alle beginpunten
local function begin(self)
	-- verzamel begin
	local van = {}
	local nietbegin = {}
	for pijl in pairs(self.pijlen) do
		-- geen lege pijl?
		if next(pijl.van) then
			nietbegin[pijl.naar] = true
		--else
			--nieuw[pijl] = true
		end
	end
	for punt in pairs(self.punten) do
		if not nietbegin[punt] then
			van[punt] = true
		end
	end

	local it = nil
	return function()
		it = next(van, it)
		return it
	end
end

local stroommeta = {
	__tostring = function(self) return self:tekst() end
}

function stroom()
	local stroom = {
		punten = {},
		pijlen = {},

		punt = function (self, punt)
			self.punten[punt] = true
		end,
		begin = begin,
		naar = naar,
		link = link,
		maglink = maglink,
		ontlink = ontlink,
		bereikbaar_disj = bereikbaar_disj,
		stroomopwaarts = bereikbaar_disj,
		tekst = tekst,
		topologisch = topologisch,
		topo = topologisch,
		kopieer = kopieer,

		-- hyperpijlen van bron
		van = function (self,bron)
			local pijl = nil
			return function()
				while next(self.pijlen, pijl) do
					local kan = next(self.pijlen, pijl)
					pijl = kan
					if kan.van[bron] then
						return kan
					end
				end
				-- klaar
				return nil
			end
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

	}

	setmetatable(stroom, stroommeta)
	return stroom
end

if test then
	-- bereikbaar disj
	local graaf = stroom()
	graaf:punt('a')
	graaf:punt('b')
	assert(not graaf:bereikbaar_disj('a', 'b'))
	graaf:link({a=true},'b')
	assert(graaf:bereikbaar_disj('a', 'b'))

	-- link
	local graaf = stroom()
	graaf:punt('a')
	graaf:punt('b')
	assert(graaf:link({a=true}, 'b'))
	assert(not graaf:link({b=true}, 'a'))

	-- superlink
	-- a->b  a,b->c
	local graaf = stroom()
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
	assert(topo[1].naar == 'b')
	assert(topo[2].naar == 'c')
end
