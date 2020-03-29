require 'vertaal'
require 'doe'
socket = require 'socket'

function langecode(maxlen)
	local len = 0
	local bron = {}

	local maakvar = maakvars()
	local prev2 = maakvar()
	local prev1 = maakvar()
	bron[#bron+1] = string.format('%s = 10', prev1)
	bron[#bron+1] = string.format('%s = 1000', prev2)
	while len < maxlen do
		local var = maakvar()
		local lijn = string.format('%s = (%s + %s) / 2 + 3', var, prev1, prev2)
		bron[#bron+1] = lijn
		len = len + #lijn + 1
		prev1,prev2 = var,prev1
	end
	bron[#bron+1] = 'uit = '..prev1
	local moetlijnen = #bron
	local lang = table.concat(bron, '\n')
	len = len + #bron[#bron]
	return lang, #bron
end

-- 10 kb
local code = langecode(10000)

local voor = socket.gettime()
uit = vertaal(code)
local na = socket.gettime()
local ms = math.floor((na - voor) * 1000)
print('10 kB vertalen duurde '..ms..' ms')
