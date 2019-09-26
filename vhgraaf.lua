require 'symbool'
require 'stroom'
require 'set'
local print = function () end

local function pijl2tekst(pijl)
	local r = {}
	for bron in pairs(pijl.van) do
		r[#r+1] = tostring(bron)
	end
	table.sort(r)
	return table.concat(r, ' ') .. ' -> ' .. tostring(pijl.naar)
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
	p[#p+1] = '' -- trigger laatste nieuwregel
	return table.concat(p, '\n')
end

-- deze wordt van achter (doel) naar voor (bron) opgebouwd
local function traceerhalfnaar(hgraaf, halfvan, naar)
	local halfnaar = maakstroom()
	local nieuwe = {}

	-- doel
	for punt in pairs(hgraaf.punten) do
		if punt == naar then
			halfnaar:punt(punt)
			nieuwe[punt] = true
		end
	end

	-- terugwerken
	while next(nieuwe) do
		local nognieuwer = {}
		for nieuw in pairs(nieuwe) do	
			for pijl in hgraaf:naar(nieuw) do
				if halfnaar:link(pijl) then
					for bron in pairs(pijl.van) do
						nognieuwer[bron] = true
					end
				end
			end
		end
		nieuwe = nognieuwer
	end
		
	return halfnaar
end

-- van: functie
-- naar: functie
-- → (stroom, halfvan, halfnaar)
local function sorteer(hgraaf, van, naar)
	if _G.verboos then print = _G.print end
	if type(van) == 'string' then van = function(a) return a == van end end
	if type(van) == 'table' then
		local van0 = van
		van = function(a) return not not van0[a] end
	end
	local maakstroom = stroom
	local stroom = maakstroom()
	local nieuw = {}
	local bekend = {}
	local nuttig = {} -- gebruikte punten

	-- verzamel begin
	for punt in pairs(hgraaf.punten) do
		print('BEGIN?', punt, van(punt))
		-- lege ingang
		local leeg = false
		for pijl in hgraaf:naar(punt) do
			if not next(pijl.van) then
				leeg = true
				print('  LEEG')
				break
			end
		end

		if leeg then
			for pijl in hgraaf:naar(punt) do
				nieuw[pijl] = true
			end
		end

		if van(punt) then
			for pijl in hgraaf:van(punt) do
				--LOG('  Nieuw! ' .. pijl2tekst(pijl))
				nieuw[pijl] = true
			end
		end
	end
	
	if not next(nieuw) then
		local halfvan = maakmaakstroom()
		local halfnaar = traceerhalfnaar(hgraaf, halfvan, naar)
		return false, halfvan, halfnaar -- TODO werk terug
	end
	--print('BEGIN:', pijl2tekst(next(nieuw)))

	while next(nieuw) do
		local pijl = next(nieuw)
		--print('LINK?',pijl2tekst(pijl))
		nieuw[pijl] = nil

		-- alle bronnen bekend?
		local ok = true
		for bron in pairs(pijl.van) do
			if not bekend[bron] and not van(bron) then
				ok = false
				--print('  NEE: '.. tostring(bron)..' is onbekend', type(bron))
			end
		end
		--print('  DOEL?', pijl.naar)

		-- mag linken
		if ok --[[and not bekend[pijl] ]] and stroom:link(pijl) then
			--print('  JA')
			for bron in pairs(pijl.van) do
				nuttig[bron] = true
			end
			bekend[pijl.naar] = true
				--print('NIEUW?', pijl.naar, type(pijl.naar))
			for pijl in hgraaf:van(pijl.naar) do
				--print('NIEUW')
				if true or not bekend[pijl.naar] then
					nieuw[pijl] = true
				else
					--print('   al bekend', pijl.naar)
				end
			end
			bekend[pijl] = true
		end

	end

	if false then
		-- snoei!
		for pijl in pairs(stroom.pijlen) do
			if not nuttig[pijl.naar] and pijl.naar ~= naar then
				stroom:ontlink(pijl)
				stroom.punten[pijl.naar] = nil
			end
		end
	end

	local b = {}
	for pijl in pairs(bekend) do
		if pijl.naar then
			--print('NAAR BEKEND', pijl.naar)
			b[pijl.naar] = true
		end
	end

	if not bekend[naar] then
		--print('NAAR ONBEKEND', naar)
		local halfvan = stroom
		local halfnaar = traceerhalfnaar(hgraaf, halfvan, naar)
		return false, halfvan, halfnaar
	end

	-- volg terug vanuit einde naar begin
	-- stop daar waar nodes onbekend zijn maar hun parents bekend

	return stroom, nil, nil
end

-- een voorwaartse hypergraaf is een hypergraaf waarbij elke hoek een specifiek punt als doel heefft
function vhgraaf()
	return {
		pijlen = {},
		punten = {},

		punt = function (self, punt)
			self.punten[punt] = true
		end;

		-- maak een hyperpijl
		link = function (h,pijl_of_van,naar)
			-- ARGS
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
			return pijl
		end,

		-- hyperpijlen vanaf bron
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

if false and test then
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

	local graaf = vhgraaf()
	local ruit = graaf
	--    / b \
	-- → a     d →
	--    \ c / 
	graaf:link(set(), 'a') -- a is een bron
	graaf:link(set'a', 'b')
	graaf:link(set'a', 'c')
	graaf:link(set'b', 'd')
	graaf:link(set'c', 'd')
	print('GRAAF')
	print(graaf:tekst())

	local stroom,fout = graaf:sorteer('a', 'd')
	assert(stroom, "oplosfout: "..tostring(fout))
	-- a -> b moet erin zitten
	assert(stroom:naar('b')() and stroom:naar('b')().van.a, stroom:tekst())
	assert(stroom:naar('c')() and stroom:naar('c')().van.a, stroom:tekst())
	local b,c
	for bc in stroom:naar('d') do
		if bc.van.b then b = 1 end
		if bc.van.c then c = 1 end
	end
	assert(b and c, stroom:tekst())


	-- FOUTEN

	-- lege graaf
	local graaf = vhgraaf()
	local stroom,halfvan,halfnaar = graaf:sorteer('a', 'b')
	assert(not stroom)
	assert(not next(halfvan.punten))
	assert(not next(halfnaar.punten))

	-- minigraaf zonder uitvoer
	local gaaf = vhgraaf()
	graaf:punt('b')
	local stroom,halfvan,halfnaar = graaf:sorteer('a', 'b')
	assert(not stroom)
	assert(not next(halfvan.punten))
	assert(halfnaar.punten.b, halfnaar:tekst())

	-- minigraaf zonder uitvoer
	local gaaf = vhgraaf()
	graaf:punt('a')
	local stroom,halfvan,halfnaar = graaf:sorteer('a', 'b')
	assert(not stroom)
	assert(not next(halfvan.punten))
	assert(next(halfnaar.punten) == 'b')

	-- kleine graaf zonder invoer
	local graaf = vhgraaf()
	graaf:link(set'a', 'b')
	local stroom,halfvan,halfnaar = graaf:sorteer('a', 'b')
	assert(not stroom)
	assert(not next(halfvan.punten))
	assert(halfnaar.punten.b)
	assert(halfnaar.punten.a)

	-- medium graaf zonder invoer
	local graaf = vhgraaf()
	graaf:link(set'a', 'b')
	graaf:link(set'b', 'c')
	local stroom,halfvan,halfnaar = graaf:sorteer('a', 'c')
	assert(not stroom)
	assert(not next(halfvan.punten))
	assert(halfnaar.punten.c)
	assert(halfnaar.punten.b)
	assert(halfnaar.punten.a)

	-- halve route niet vervulbaar
	-- → a
	-- a → b
	-- b c → d
	local graaf = vhgraaf()
	graaf:link(set(), 'a')
	graaf:link(set('a'), 'b')
	graaf:link(set('b','c'), 'd')
	verboos = true
	local stroom,halfvan,halfnaar = graaf:sorteer('a', 'd')
	assert(not stroom)
	assert(next(halfvan.pijlen))
	assert(halfvan.punten.a, tostring(halfvan))
	assert(halfvan.punten.b, tostring(halfvan))
	assert(halfnaar.punten.d, tostring(halfnaar))


end
