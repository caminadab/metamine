require 'util'
require 'lisp'

require 'ontleed'
require 'noem'
require 'sorteer'
require 'typeer'
require 'uitrol'
require 'vhgraaf'
require 'ontrafel'
require 'plan'

require 'js'

-- a := b => (start => a = b)
-- (a => b = c) => b = (a => c)
-- a += b => (beeld => a = a' + 1/60)

function sorteer(kennis)
	local afh,map = berekenbaarheid(kennis)
	local infostroom,fout = afh:sorteer('in', 'uit')
	if not infostroom then
		return false,fout
	end

	-- terugmappen
	local stroom = {}
	for pijl,naar in infostroom:topologisch(map) do
		stroom[#stroom+1] = map[pijl]
	end
	return stroom
end

--[[
vertaal = code -> stroom
	ontleed: code -> kennis
	noem: feiten => (naam -> exp)
	sorteer: namen -> stroom

	typeer stroom
	uitrol: stroom -> makkelijke-stroom
]]
function vertaal(code)
	local kennis = ontleed(code)
	if not kennis then return false,'ontleed' end

	-- herleidt alle info
	--local kennis = ontrafel(kennis)
	--local kennis = deduceer(kennis)
	local kennis = ontrafel(kennis)
	
	-- sorteer
	local stroom,fout = sorteer(kennis)

	return stroom,fout
end
