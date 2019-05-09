require 'func'

local metagraaf = {}

function pijl2tekst(pijl)
	local van = ''
	if pijl.van then
		van = tostring(pijl.van)
	end
	return van .. ' -> ' .. tostring(pijl.naar)
end

function metagraaf:tekst()
	if not next(self.punten) and not next(self.pijlen) then
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

function metagraaf:link(pijl_of_van, naar)
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

	self.pijlen[pijl] = true

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

	self.pijlen[pijl] = nil
end

function metagraaf:punt(punt)
	self.punten[punt] = true
end

-- pijlen naar doel
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
	}

	setmetatable(graaf, graafmeta)
	
	return graaf
end
