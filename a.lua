require 'ontleed'
require 'util'
require 'exp'
require 'symbool'

local maakvar = maakvars()
local t = {'qa = 1\n'}

local a = 'q'..maakvar():lower()
for i=1,1e6 do
	local b = 'q'..maakvar():lower()
	t[#t+1] = b .. ' = ' .. a .. '\n'
	a = b
end

print(table.concat(t))


