require 'func'

local metagraaf = {}

local function punt2tekst(punt)
	local p = tostring(punt)
	local q = p:match '([^\n]*)'
	if q then
		p = q .. '...'
	end
	return p
end

local function pijl2tekst(pijl)
	return punt2tekst(pijl.van) .. ' -> ' .. punt2tekst(pijl.naar)
end

function metagraaf:tekst()
	if not next(self.punten) and not next(self.pijlen) then
		return '<lege graaf>'
	end
	local p2 = {}
	local al = {}
	for pijl in pairs(self.pijlen) do
		al[pijl.naar] = true
		al[pijl.van] = true
		p2[#p2+1] = pijl2tekst(pijl)
	end
	local p1 = {}
	for punt in pairs(self.punten) do
		if not al[punt] then
			table.insert(p1, punt2tekst(punt)..'.')
		end
	end
	table.sort(p1)
	table.sort(p2)
	return table.concat(p1, '\n') .. '\n' .. table.concat(p2, '\n')
end

function metagraaf:kopieer()
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

function metagraaf:topologisch()
	if not next(self.pijlen) then
		return {}
	end

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
		local naam = volgorde[i].van
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
-- O(n)
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

function metagraaf:link(van, naar)
	local pijl = {van = van, naar = naar}

	-- per van
	if self.pervan[van] and self.pervan[van][naar] then
		return self.pervan[van][naar]
	end
	self.pervan[van] = self.pervan[van] or {}
	self.pervan[van][naar] = true

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
	self.punten[van] = true
	return pijl
end

function metagraaf:ontlink(pijl_of_van, naar)
	local van, pijl
	if naar then
		van = pijl_of_van
		pijl = {van=van,naar=naar}
	else
		pijl = pijl_of_van
		van = pijl.van
		naar = pijl.naar 
	end

	self.pervan[van][naar] = nil
	if not next(self.pervan[van]) then self.pervan[van] = nil end
	self.pijlen[pijl] = nil
end

function metagraaf:punt(punt)
	self.punten[punt] = true
	self.pervan[punt] = self.pervan[punt] or {}
end

-- pijlen naar doel
-- O(m)
function metagraaf:naar(doel)
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
-- O(m)
function metagraaf:van(bron)
	local pijl = nil
	return function()
		while next(self.pijlen, pijl) do
			local kan = next(self.pijlen, pijl)
			pijl = kan
			if kan.van == bron then
				return kan
			end
		end
		-- klaar
		return nil
	end
end

local graafmeta = {
	__tostring = function(self) return self:tekst() end,
	__index = metagraaf,
}

function maakgraaf()
	local graaf = {
		punten = {},
		pijlen = {},
		pervan = {}, -- van -> {naar}
	}

	setmetatable(graaf, graafmeta)
	
	return graaf
end
