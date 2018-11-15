require 'stroom'
require 'symbool'
local print = function () end

local function pijl2tekst(pijl)
	local r = {}
	for bron in pairs(pijl.van) do
		r[#r+1] = tostring(bron)
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

local function sorteer(hgraaf, van, naar)
	if _G.verboos then print = _G.print end
	if isatoom(van) then van = {[van] = true} end
	local stroom = stroom()
	local nieuw = {}
	local bekend = {}
	local nuttig = {} -- gebruikte punten

	-- verzamel begin
	for punt in pairs(van) do
		for pijl in hgraaf:van(punt) do
			nieuw[pijl] = true
			print('BEGIN',pijl2tekst(pijl))
		end
	end
	if not next(nieuw) then
		_G.print(hgraaf:tekst())
		return false,'geen begin gevonden'
	end

	while next(nieuw) do
		local pijl = next(nieuw)
		print('LINK?',pijl2tekst(pijl))
		nieuw[pijl] = nil

		-- alle bronnen bekend?
		local ok = true
		for bron in pairs(pijl.van) do
			if not bekend[bron] and not van[bron] then
				ok = false
				print('  NEE: '.. bron..' is onbekend', type(bron))
			end
		end
		print('  DOEL?', pijl.naar)

		-- mag linken
		if ok --[[and not bekend[pijl] ]] and stroom:link(pijl) then
			print('  JA', type(pijl.naar))
			for bron in pairs(pijl.van) do
				nuttig[bron] = true
			end
			bekend[pijl.naar] = true
			for pijl in hgraaf:van(pijl.naar) do
				if true or not bekend[pijl.naar] then
					nieuw[pijl] = true
				else
					print('   al bekend', pijl.naar)
				end
			end
			bekend[pijl] = true
		end

	end

	-- snoei!
	for pijl in pairs(stroom.pijlen) do
		if not nuttig[pijl.naar] and pijl.naar ~= naar then
			stroom:ontlink(pijl)
			stroom.punten[pijl.naar] = nil
		end
	end

	if not bekend[naar] then
		return false,'doel "'..naar..'" niet bereikt',stroom
	end

	return stroom
end

-- een voorwaartse hypergraaf is een hypergraaf waarbij elke hoek een specifiek punt als doel heefft
function vhgraaf()
	return {
		pijlen = {},
		punten = {},

		-- maak een hyperpijl
		link = function (h,pijl_of_van,naar)
			local van, pijl
			if naar then
				van = pijl_of_van
				pijl = {van=van,naar=naar}
			else
				pijl = pijl_of_van
				van = pijl.van
				naar = pijl.naar 
			end
			if type(van) ~= 'table' then van = {[van]=true} end

			for bron in pairs(van) do
				h.punten[bron] = true
			end
			h.punten[naar] = true
			h.pijlen[pijl] = true
			return pijl
		end,

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

		sorteer = sorteer,
		tekst = tekst,
	}
end

require 'util'

if test then
	-- link
	local graaf = vhgraaf()
	graaf:link(set('a'), 'b')
	assert(graaf:naar('b')().van.a)

	-- sorteer
	local graaf = vhgraaf()
	graaf:link(set('a'), 'b')
	graaf:link(set('b'), 'a')
	local stroom = graaf:sorteer(set('a'), 'b')
	assert(stroom:naar('b')().van.a)

	-- sorteer 2
	local graaf = vhgraaf()
	graaf:link(set('a'), 'b')
	graaf:link(set('b'), 'c')
	graaf:link(set('c'), 'a')
	local stroom = graaf:sorteer(set('a'), 'c')
	assert(stroom:naar('c')().van.b)
	assert(stroom:naar('b')().van.a)

	--[[ 
	Graaf:
		IN -> A
		B -> A
		A -> B
		A, B -> UIT
	Foute keuze maken is mogelijk:
		A, B -> UIT
		B -> A
		GEEN OPTIES MEER
	Goed:
		A, B -> UIT
		A -> B
		IN -> A
	]]

	local graaf = vhgraaf()
	--graaf:link(set('in'), 'a')
	graaf:link(set('in'), 'a')
	graaf:link(set('b'), 'a')
	graaf:link(set('a'), 'b')
	graaf:link(set('a', 'b'), 'uit')
	local stroom = graaf:sorteer(set('in'), 'uit')
	-- a -> b moet erin zitten
	assert(stroom:naar('b')() and stroom:naar('b')().van.a, stroom:tekst())

end

if true then
	local graaf = vhgraaf()
	--   / b \
	--  a     d
	--   \ c / 
	graaf:link(set'a', 'b')
	graaf:link(set'a', 'c')
	graaf:link(set'b', 'd')
	graaf:link(set'c', 'd')
	print('GRAAF')
	print(graaf:tekst())

	local stroom,fout = graaf:sorteer('a', 'd')
	-- a -> b moet erin zitten
	assert(stroom:naar('b')() and stroom:naar('b')().van.a, stroom:tekst())
	assert(stroom:naar('c')() and stroom:naar('c')().van.a, stroom:tekst())
	local b,c
	for bc in stroom:naar('d') do
		if bc.van.b then b = 1 end
		if bc.van.c then c = 1 end
	end
	assert(b and c, stroom:tekst())
end
