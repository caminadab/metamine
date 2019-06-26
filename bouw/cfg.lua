require 'graaf'
require 'util'
require 'combineer'
require 'bouw.blok'

-- { graaf, blokken }
local metacfg = {}


function metacfg:link(naam, stats)
	assert(not self.blokken[naam], 'dubbele bloknaam: '..naam)
	self.blokken[naam] = stats
	self.graaf:punt(naam)
end

local cfgmeta = {}
cfgmeta.__index = metacfg

--[[
start.

start:
	t := 2
	s := t + 3
	stop
]]
function cfgmeta:__tostring()
	local t = {}
	t[#t+1] = tostring(self.graaf)
	t[#t+1] = '\n'
	do return end

	for blok in spairs(self.blokken) do
		t[#t+1] = naam
		t[#t+1] = ':\n'
		for i,stat in ipairs(blok) do
			t[#t+1] = '  '
			t[#t+1] = combineer(stat)
			do
				t[#t+1] = '  '
				t[#t+1] = loctekst(stat[2].loc)
				t[#t+1] = '!!!'
			end
			t[#t+1] = '\n'
		end
		t[#t+1] = '\n'
	end
	return table.concat(t)
end

function leescfg(tekst)
	local cfg = maakcfg()
	local tekst = '\n'..tekst:gsub('\t', '') .. '\n'

	local labels = {}
	local tekst = tekst:gsub('\n([^\n:]+:\n)', function(blok) return '@'..blok end)

	local refs = {}
	for stuk in tekst:gmatch "@([^@]+)" do
		local blok = leesblok(stuk)
		refs[blok.naam.v] = blok
		cfg:punt(blok)
	end

	-- link & check refs
	for blok in pairs(cfg.punten) do
		if fn(blok.epiloog) == 'ga' then
			if fn(blok.epiloog[1]) == ',' then
				-- multi
				for i=2,#blok.epiloog[1] do
					local label = blok.epiloog[1][i]
					local ref = refs[label.v]
					assert(ref, 'onbekend label '..label.v)
					cfg:link(blok, ref)
				end
			else 
				local label = blok.epiloog[1]
				local ref = refs[label.v]
				assert(ref, 'onbekend label '..label.v)
				cfg:link(blok, ref)
			end
		end
	end

	return cfg
end

function maakcfg()
	do return maakgraaf() end
	local cfg = {
		graaf = maakgraaf(),
		blokken = {}
	}

	setmetatable(cfg, cfgmeta)
	return cfg
end

if false and test then
	require 'ontleed'
	require 'oplos'
	require 'util'

	local a = leescfg [[
start:
	a := 3
	ga lus
lus:
	stop
]]

	local b = leescfg(file "bouw/b.rtl")


end
	
