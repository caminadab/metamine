require 'symbol'
require 'flow'
require 'set'
local print = function () end

local function pijl2text(pijl)
	local r = {}
	for bron in pairs(pijl.van) do
		r[#r+1] = tostring(bron)
	end
	table.sort(r)
	return table.concat(r, ' ') .. ' -> ' .. tostring(pijl.naar)
end

local function text(graph)
	if not next(graph.pijlen) then
		return '<lege graph>'
	end
	local p = {}
	for pijl in pairs(graph.pijlen) do
		p[#p+1] = pijl2text(pijl)
	end
	table.sort(p)
	p[#p+1] = '' -- trigger laatste nieuwregel
	return table.concat(p, '\n')
end

-- deze wordt van achter (doel) naar voor (bron) opgebouwd
local function traceerhalfnaar(hgraph, halfvan, naar)
	local halfnaar = maakflow()
	local nieuwe = {}

	-- doel
	for punt in pairs(hgraph.punten) do
		if punt == naar then
			halfnaar:punt(punt)
			nieuwe[punt] = true
		end
	end

	-- terugwerken
	while next(nieuwe) do
		local nognieuwer = {}
		for nieuw in pairs(nieuwe) do	
			for pijl in hgraph:naar(nieuw) do
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
-- → (flow, halfvan, halfnaar)
local function sorteer(hgraph, van, naar)
	if _G.verboos then print = _G.print end
	if type(van) == 'string' then van = function(a) return a == van end end
	if type(van) == 'table' then
		local van0 = van
		van = function(a) return not not van0[a] end
	end
	local flow = maakflow()
	local nieuw = {}
	local bekend = {}
	local nuttig = {} -- gebruikte punten

	-- verzamel begin
	for punt in pairs(hgraph.punten) do
		print('BEGIN?', punt, van(punt))
		-- lege ingang
		local leeg = false
		for pijl in hgraph:naar(punt) do
			if not next(pijl.van) then
				leeg = true
				print('  LEEG')
				break
			end
		end

		if leeg then
			for pijl in hgraph:naar(punt) do
				nieuw[pijl] = true
			end
		end

		if van(punt) then
			for pijl in hgraph:van(punt) do
				--LOG('  Nieuw! ' .. pijl2text(pijl))
				nieuw[pijl] = true
			end
		end
	end
	
	if not next(nieuw) then
		local halfvan = maakflow()
		local halfnaar = traceerhalfnaar(hgraph, halfvan, naar)
		return false, halfvan, halfnaar -- TODO werk terug
	end
	--print('BEGIN:', pijl2text(next(nieuw)))

	while next(nieuw) do
		local pijl = next(nieuw)
		--print('LINK?',pijl2text(pijl))
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
		if ok --[[and not bekend[pijl] ]] and flow:link(pijl) then
			--print('  JA')
			for bron in pairs(pijl.van) do
				nuttig[bron] = true
			end
			bekend[pijl.naar] = true
				--print('NIEUW?', pijl.naar, type(pijl.naar))
			for pijl in hgraph:van(pijl.naar) do
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
		for pijl in pairs(flow.pijlen) do
			if not nuttig[pijl.naar] and pijl.naar ~= naar then
				flow:ontlink(pijl)
				flow.punten[pijl.naar] = nil
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
		local halfvan = flow
		local halfnaar = traceerhalfnaar(hgraph, halfvan, naar)
		return false, halfvan, halfnaar
	end

	-- volg terug vanuit einde naar begin
	-- stop daar waar nodes onbekend zijn maar hun parents bekend

	return flow, nil, nil
end

-- een voorwaartse hyperflow is een hyperflow waarbij elke hoek een specifiek punt als doel heefft
function hyperflow()
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
		end,

		sorteer = sorteer,
		text = text,
	}
end

require 'util'

if false and test then
	-- link
	local graph = hyperflow()
	graph:link(set('a'), 'b')
	assert(graph:naar('b')().van.a)

	-- sorteer
	local graph = hyperflow()
	graph:link(set('a'), 'b')
	graph:link(set('b'), 'a')
	local flow = graph:sorteer(set('a'), 'b')
	assert(flow:naar('b')().van.a)

	-- sorteer 2
	local graph = hyperflow()
	graph:link(set('a'), 'b')
	graph:link(set('b'), 'c')
	graph:link(set('c'), 'a')
	local flow = graph:sorteer(set('a'), 'c')
	assert(flow:naar('c')().van.b)
	assert(flow:naar('b')().van.a)

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

	local graph = hyperflow()
	--graph:link(set('in'), 'a')
	graph:link(set('in'), 'a')
	graph:link(set('b'), 'a')
	graph:link(set('a'), 'b')
	graph:link(set('a', 'b'), 'uit')
	local flow = graph:sorteer(set('in'), 'uit')
	-- a -> b moet erin zitten
	assert(flow:naar('b')() and flow:naar('b')().van.a, flow:text())

	local graph = hyperflow()
	local ruit = graph
	--    / b \
	-- → a     d →
	--    \ c / 
	graph:link(set(), 'a') -- a is een bron
	graph:link(set'a', 'b')
	graph:link(set'a', 'c')
	graph:link(set'b', 'd')
	graph:link(set'c', 'd')
	print('GRAAF')
	print(graph:text())

	local flow,fout = graph:sorteer('a', 'd')
	assert(flow, "solvefout: "..tostring(fout))
	-- a -> b moet erin zitten
	assert(flow:naar('b')() and flow:naar('b')().van.a, flow:text())
	assert(flow:naar('c')() and flow:naar('c')().van.a, flow:text())
	local b,c
	for bc in flow:naar('d') do
		if bc.van.b then b = 1 end
		if bc.van.c then c = 1 end
	end
	assert(b and c, flow:text())


	-- FOUTEN

	-- lege graph
	local graph = hyperflow()
	local flow,halfvan,halfnaar = graph:sorteer('a', 'b')
	assert(not flow)
	assert(not next(halfvan.punten))
	assert(not next(halfnaar.punten))

	-- minigraph zonder uitvoer
	local gaaf = hyperflow()
	graph:punt('b')
	local flow,halfvan,halfnaar = graph:sorteer('a', 'b')
	assert(not flow)
	assert(not next(halfvan.punten))
	assert(halfnaar.punten.b, halfnaar:text())

	-- minigraph zonder uitvoer
	local gaaf = hyperflow()
	graph:punt('a')
	local flow,halfvan,halfnaar = graph:sorteer('a', 'b')
	assert(not flow)
	assert(not next(halfvan.punten))
	assert(next(halfnaar.punten) == 'b')

	-- kleine graph zonder invoer
	local graph = hyperflow()
	graph:link(set'a', 'b')
	local flow,halfvan,halfnaar = graph:sorteer('a', 'b')
	assert(not flow)
	assert(not next(halfvan.punten))
	assert(halfnaar.punten.b)
	assert(halfnaar.punten.a)

	-- medium graph zonder invoer
	local graph = hyperflow()
	graph:link(set'a', 'b')
	graph:link(set'b', 'c')
	local flow,halfvan,halfnaar = graph:sorteer('a', 'c')
	assert(not flow)
	assert(not next(halfvan.punten))
	assert(halfnaar.punten.c)
	assert(halfnaar.punten.b)
	assert(halfnaar.punten.a)

	-- halve route niet vervulbaar
	-- → a
	-- a → b
	-- b c → d
	local graph = hyperflow()
	graph:link(set(), 'a')
	graph:link(set('a'), 'b')
	graph:link(set('b','c'), 'd')
	verboos = true
	local flow,halfvan,halfnaar = graph:sorteer('a', 'd')
	assert(not flow)
	assert(next(halfvan.pijlen))
	assert(halfvan.punten.a, tostring(halfvan))
	assert(halfvan.punten.b, tostring(halfvan))
	assert(halfnaar.punten.d, tostring(halfnaar))


end
