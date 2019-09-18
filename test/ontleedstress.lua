package.path = package.path ..';../?.lua'
require 'util'
require 'exp'
require 'combineer'

-- 1 MB
--local maxlen = 1024 * 1024
local maxlen = 1024 * 1024
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

-- ontleed
require 'ontleed'
local socket = require 'socket'

-- ⋀([](...))
local voor = socket.gettime()
local lang = ontleed(lang)
local na = socket.gettime()
local dt = na - voor

local snelheid = maxlen / 1024 / 1024 / dt

local numlijnen = #lang.a
print(string.format('%s lijnen (%d MB) ontleed in %d ms (%.3f MB/s)',
		numlijnen, maxlen/1024/1024, dt*1000, snelheid))

if numlijnen ~= #bron then
	print('FOUT!', numlijnen..' lijnen ontleed, maar moeten er '..moetlijnen..' zijn')
	local feiten = lang.a
	print(combineer(feiten[#feiten]))
end
