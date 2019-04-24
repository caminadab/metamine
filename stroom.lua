require 'func'

	--[[
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
		]]

local metastroom = {}

-- is er, zonder alle pijlen te vervullen, een route van bron naar doel mogelijk?
-- zoekt achterstevoren
function metastroom:stroomopwaarts(van, naar)
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
		for pijl in self:naar(punt) do
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

function metastroom:stroomafwaarts(naar, van)
	return metastroom:stroomopwaarts(van, naar)
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

function metastroom:tekst()
	if not next(self.pijlen) then
		return '<lege graaf>'
	end
	local p2 = {}
	local al = {}
	for pijl in pairs(self.pijlen) do
		al[pijl.naar] = true
		for bron in pairs(pijl.van) do al[bron] = true end
		p2[#p2+1] = pijl2tekst(pijl)
	end
	local p1 = {}
	for punt in pairs(self.punten) do
		if not al[punt] then
			table.insert(p1, tostring(punt)..'.')
		end
	end
	table.sort(p1)
	table.sort(p2)
	return table.concat(p1, '\n') .. '\n' .. table.concat(p2, '\n')
end

function metastroom:kopieer()
	local kopie = {punten = {}, pijlen = {}}
	for k,v in pairs(self) do
		if k ~= 'punten' and k ~= 'pijlen' then
			kopie[k] = v
		end
	end
		
	for punt in pairs(self.punten) do
		kopie.punten[punt] = true
	end
	for pijl in pairs(self.pijlen) do
		kopie.pijlen[pijl] = true
	end
	return kopie
end

function metastroom:topologisch()
	--local print = function () end
	--TODO if isatoom(van) then van = {[van] = true} end
	local volgorde = {}
	local nieuw = {}
	local bekend = {}

	-- verzamel begin
	local van = {}
	local nietbegin = {}
	for pijl in pairs(self.pijlen) do
		-- geen lege pijl?
		if next(pijl.van) then
			nietbegin[pijl.naar] = true
		else
			nieuw[pijl] = true
		end
	end
	for punt in pairs(self.punten) do
		if not nietbegin[punt] then
			van[punt] = true
		end
	end

	for punt in pairs(van) do
		for pijl in self:van(punt) do
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
			for pijl in self:van(pijl.naar) do
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

function metastroom:maglink(pijl_of_van, naar)
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
		if self:stroomopwaarts(naar, bron) then
			return false
		end
	end

	-- zit hij er al in?
	for alpijl in pairs(self.pijlen) do
		-- TODO kijk ook naar andere bronnen
		if next(alpijl.van) == next(pijl.van) and pijl.naar == alpijl.naar then
			return false
		end
	end

	return true
end

function metastroom:link(pijl_of_van, naar)
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

	if not self:maglink(pijl) then
		return false
	end

	self.pijlen[pijl] = true

	-- werk begin bij
	if self.begin[pijl.naar] then
		self.begin[pijl.naar] = nil
	end
	for bron in pairs(pijl.van) do
		if not self.punten[bron] then
			self.begin[bron] = true
		end
	end

	-- registreer punten
	self.punten[naar] = true
	for bron in pairs(van) do
		self.punten[bron] = true
	end


	return pijl
end

function metastroom:ontlink(pijl_of_van, naar)
	local van, pijl
	if naar then
		van = pijl_of_van
		pijl = {van=van,naar=naar}
	else
		pijl = pijl_of_van
		van = pijl.van
		naar = pijl.naar 
	end

	self.pijlen[pijl] = nil
end

-- iterator over alle beginpunten
function metastroom:begin(self)
	local begin = self.begin
	local it = nil
	return function()
		it = next(begin, it)
		return it
	end
end

function metastroom:punt(punt)
	self.punten[punt] = true
end

-- hyperpijlen naar doel
function metastroom:naar(doel)
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
end

-- hyperpijlen van bron
function metastroom:van(bron)
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
end

local stroommeta = {
	__tostring = function(self) return self:tekst() end,
	__index = metastroom,
}

function stroom()
	local stroom = {
		punten = {},
		pijlen = {},
		begin = {},
	}

	setmetatable(stroom, stroommeta)
	
	return stroom
end

if test then
	-- bereikbaar disj
	local graaf = stroom()
	graaf:punt('a')
	graaf:punt('b')
	assert(not graaf:stroomopwaarts('a', 'b'))
	graaf:link({a=true},'b')
	assert(graaf:stroomopwaarts('a', 'b'))

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
