require 'graaf'
require 'util'
require 'combineer'

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

	for naam,blok in spairs(self.blokken) do
		t[#t+1] = naam
		t[#t+1] = ':\n'
		for i,stat in ipairs(blok) do
			t[#t+1] = '  '
			t[#t+1] = combineer(stat)
			t[#t+1] = '\n'
		end
		t[#t+1] = '\n'
	end
	return table.concat(t)
end

function maakcfg()
	local cfg = {
		graaf = maakgraaf(),
		blokken = {}
	}

	setmetatable(cfg, cfgmeta)
	return cfg
end


if test then
	require 'ontleed'
	require 'oplos'

	local src = [[
a = 2 / 3  ; delen is moeilijk
f(x) = x + 1 ; functies niet
exitcode = a + f(2)
]]

	local a = maakcfg()
	a:link('start', oplos(ontleed(src)))

	--'a := 3\nret := a + 3\nstop')
	--a:link('fn', E'x := arg 0 \n ret := x + 1')

	--local fn = maakblok('fn', E'x := arg 0 \n ret := x + 1')

	print(a)
end
	
