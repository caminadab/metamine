require 'func'

local metaflow = {}

-- is er een route van 'van' naar 'naar' mogelijk?
-- zoekt achterstevoren
-- O(n·m)
function metaflow:flowopwaarts(van, naar)
	--print()
	--print('# start')

	--print(tostring(naar)..' ?-> '..tostring(van))

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

function metaflow:flowafwaarts(naar, van)
	return self:flowopwaarts(van, naar)
end

function pijl2text(pijl)
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

function metaflow:text()
	if not next(self.pijlen) then
		return '<lege graph>'
	end
	local p2 = {}
	local al = {}
	for pijl in pairs(self.pijlen) do
		al[pijl.naar] = true
		for bron in pairs(pijl.van) do al[bron] = true end
		p2[#p2+1] = pijl2text(pijl)
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

function metaflow:copy()
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

function metaflow:topologisch()
	if not next(self.pijlen) then
		return {}
	end

	--local print = function () end
	--TODO if isatom(van) then van = {[van] = true} end
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

	for punt in pairs(self.begin) do
		for pijl in self:van(punt) do
			nieuw[pijl] = true
		end
	end
	if not next(nieuw) then
		return false,'geen begin gevonden'
	end

	while next(nieuw) do
		local pijl = next(nieuw)
		--print('LINK?',pijl2text(pijl))
		nieuw[pijl] = nil

		-- alle bronnen bekend?
		local ok = true
		for bron in pairs(pijl.van) do
			if bron == pijl.naar then
				ok = false
			end
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
		local name = volgorde[i]
		if al[name] then table.remove(volgorde,i)
		else al[name] = true end
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

function metaflow:maglink(pijl_of_van, naar)
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
		if self:flowopwaarts(naar, bron) then
			return false
		end
	end

	-- zit hij er al in?
	--[[
	for alpijl in pairs(self.pijlen) do
		-- TODO kijk ook naar andere bronnen
		if next(alpijl.van) == next(pijl.van) and pijl.naar == alpijl.naar then
			return false
		end
	end
	--]]

	return true
end

function metaflow:link(pijl_of_van, naar)
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
	if not next(pijl.van) then
		self.begin[pijl.naar] = true
	end
	for bron in pairs(pijl.van) do
		if not self.punten[bron] then
			self.begin[bron] = true
		end
	end

	-- werk van bij
	for bron in pairs(pijl.van) do
		self.van2pijl[bron] = self.van2pijl[bron] or {}
		self.van2pijl[bron][pijl] = true
	end

	-- werk naar bij
	self.naar2pijl[pijl.naar] = self.naar2pijl[pijl.naar] or {}
	self.naar2pijl[pijl.naar][pijl] = true

	-- registreer punten
	self.punten[naar] = true
	for bron in pairs(van) do
		self.punten[bron] = true
	end


	return pijl
end

function metaflow:ontlink(pijl_of_van, naar)
	local van, pijl
	if naar then
		van = pijl_of_van
		pijl = {van=van,naar=naar}
	else
		pijl = pijl_of_van
		van = pijl.van
		naar = pijl.naar 
	end

	-- werk van bij
	for bron in pairs(pijl.van) do
		self.van2pijl[bron][pijl] = nil
		if not next(self.van2pijl[bron]) then
			self.van2pijl[bron] = nil
		end
	end

	-- werk naar bij
	self.naar2pijl[pijl.naar][pijl] = nil
	self.naar2pijl[pijl.naar] = self.naar2pijl[pijl.naar] or {}
	if not next(self.naar2pijl[pijl.naar]) then
		self.naar2pijl[pijl.naar] = nil
	end


	self.pijlen[pijl] = nil
end

-- iterator over alle beginpunten
function metaflow:begin(self)
	local begin = self.begin
	local it = nil
	return function()
		it = next(begin, it)
		return it
	end
end

function metaflow:punt(punt)
	self.punten[punt] = true
	self.begin[punt] = true
end

-- hyperpijlen naar doel
function metaflow:naar(doel)
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

function metaflow:van(bron)
	if not self.van2pijl[bron] then
		return function() return nil end
	end
	return pairs(self.van2pijl[bron])
end

function metaflow:naar(bron)
	if not self.naar2pijl[bron] then
		return function() return nil end
	end
	return pairs(self.naar2pijl[bron])
end

-- hyperpijlen van bron
function metaflow:van0(bron)
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

local flowmeta = {
	__tostring = function(self) return self:text() end,
	__index = metaflow,
}

function maakflow()
	local flow = {
		punten = {},
		pijlen = {},
		begin = {},
		van2pijl = {},
		naar2pijl = {},
	}

	setmetatable(flow, flowmeta)
	
	return flow
end

if test then
	-- bereikbaar disj
	local graph = maakflow()
	graph:punt('a')
	graph:punt('b')
	assert(not graph:flowopwaarts('a', 'b'))
	graph:link({a=true},'b')
	assert(graph:flowopwaarts('a', 'b'))

	-- link
	local graph = maakflow()
	graph:punt('a')
	graph:punt('b')
	assert(graph:link({a=true}, 'b'))
	assert(not graph:link({b=true}, 'a'))

	-- superlink
	-- a->b  a,b->c
	local graph = maakflow()
	graph:punt('a')
	graph:punt('b')
	graph:punt('c')
	assert(graph:link({a=true}, 'b'))
	assert(graph:link({a=true,b=true}, 'c'))
	-- b->a mag niet
	assert(not graph:link({b=true}, 'a'))
	-- a,c->b mag niet
	assert(not graph:link({a=true,c=true}, 'b'))

	-- topologisch
	local topo,fouten = graph:topologisch()
	assert(not fouten, tostring(graph)) --table.concat(fouten))
	assert(topo[1].naar == 'b')
	assert(topo[2].naar == 'c')
end
