require 'voorwaartse_acyclische_hypergraaf'

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

--[[
local function sorteer_itereer(onbekend)
	-- VOOR ELKE PIJL
	for punt in pairs(onbekend) do
		for pijl in graaf:naar(punt) do
			-- voeg toe
			if stroom:pijl(pijl) then
				local af = sorteer_itereer(...)
				if af then
					return af
				end
			end
		end
	end

	print('Opties uitgeput, geen resultante')
	return false
end

local function sorteer(graaf, van, naar)
	local stroom = voorwaartse_acyclische_hypergraaf()
	
	return sorteer_itereer(...)

	--[[
	voor elke onontdekte pijl doe
		voeg hem toe
		recurseer
	]]
--end

-- bedenk alle hyperroutes door hypergraaf
local function sorteer(hgraaf, van, naar)
	--print = function () end
	local onbekend = {}
	for pijl in hgraaf:naar(naar) do
		onbekend[pijl] = true
	end
	local stroom = voorwaartse_acyclische_hypergraaf()
	local bekend = {}
	local fout = {}

	-- alle mogelijke opties
	while next(onbekend) do
		local pijl = next(onbekend)
		bekend[pijl] = true
		onbekend[pijl] = nil

		local doodlopend = false

		if stroom:link(pijl) then
			print('LINK', pijl2tekst(pijl))
			bekend[pijl] = true
			for punt in pairs(pijl.van) do
				print('  BRON', punt)

				-- zoek verder als dit niet START is,
				if not van[punt] then
					local iets = false

					for pijl in hgraaf:naar(punt) do
						-- wanneer proberen?
						local mag = stroom:maglink(pijl)
						print('   MAG?',pijl2tekst(pijl),mag and 'ja' or 'nee')

						if stroom:maglink(pijl) then
							iets = true

							if not bekend[pijl] and not fout[pijl] then
								onbekend[pijl] = true
								print('    mogelijkheid',pijl2tekst(pijl))
							end
						end
					end

					if not iets then
						doodlopend = true
					end
				
				-- START: wat dit punt betreft is alles O.K.
				else
					print('   OK:',punt)
				end

			end
		end

		if doodlopend then
			print('DOODLOPEND!!', pijl2tekst(pijl))
			stroom:ontlink(pijl)
			fout[pijl] = true

			-- opnieuw
			local kan = false
			for pijl in hgraaf:naar(pijl.naar) do
				if not fout[pijl] then
					kan = true
					print('  OPTIE', pijl2tekst(pijl))
					onbekend[pijl] = true
				end
			end
			if not kan then --and not next(onbekend) then
				print("NEEEEEEEEEEEE")
				return false
			end
		end
	end

	print('KLAAR')
	print(stroom:tekst())

	return stroom
			
end

function sorteer(hgraaf, van, naar)
	local stroom = voorwaartse_acyclische_hypergraaf()
	local nieuw = {}
	local bekend = {}

	-- verzamel begin
	for punt in pairs(van) do
		for pijl in hgraaf:van(punt) do
			nieuw[pijl] = true
			print('BEGIN',pijl2tekst(pijl))
		end
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
				print('ONBEKEND', bron)
			end
		end

		if ok and not bekend[pijl] and stroom:link(pijl) then
			print('LINK',pijl2tekst(pijl))
			bekend[pijl.naar] = true
			for pijl in hgraaf:van(pijl.naar) do
				if not bekend[pijl.naar] then
					nieuw[pijl] = true
				end
			end
			bekend[pijl] = true
		end

	end
	print('KLAAR')
	print(stroom:tekst())

	return stroom
end

-- een voorwaartse hypergraaf is een hypergraaf waarbij elke hoek een specifiek punt als doel heefft
function voorwaartse_hypergraaf()
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

			for bron in pairs(van) do
				h.punten[bron] = true
			end
			h.punten[naar] = true
			h.pijlen[pijl] = true
		end,

		-- hyperpijlen van bron
		van = function (self,bron)
			local hoek = nil
			return function()
				while next(self.pijlen, hoek) do
					local kan = next(self.pijlen, hoek)
					hoek = kan
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
	local graaf = voorwaartse_hypergraaf()
	graaf:link(set('a'), 'b')
	assert(graaf:naar('b')().van.a)

	-- sorteer
	local graaf = voorwaartse_hypergraaf()
	graaf:link(set('a'), 'b')
	graaf:link(set('b'), 'a')
	local stroom = graaf:sorteer(set('a'), 'b')
	assert(stroom:naar('b')().van.a)

	-- sorteer 2
	local graaf = voorwaartse_hypergraaf()
	graaf:link(set('a'), 'b')
	graaf:link(set('b'), 'c')
	graaf:link(set('c'), 'a')
	local stroom = graaf:sorteer(set('a'), 'c')
	assert(stroom:naar('c')().van.b)
	assert(stroom:naar('b')().van.a)
end

if true then
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
	local graaf = voorwaartse_hypergraaf()
	--graaf:link(set('in'), 'a')
	graaf:link(set('in'), 'a')
	graaf:link(set('b'), 'a')
	graaf:link(set('a'), 'b')
	graaf:link(set('a', 'b'), 'uit')
	local stroom = graaf:sorteer(set('in'), 'uit')
	-- a -> b moet erin zitten
	assert(stroom:naar('b')() and stroom:naar('b')().van.a, stroom:tekst())

end
