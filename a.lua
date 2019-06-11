require 'ontleed'
require 'util'
require 'exp'
require 'symbool'

local maakvar = maakvars()
local t = {'piepa = 1\n'}

local a = 'piep'..maakvar():lower()
for i=1,1000 do
	local b = 'piep'..maakvar():lower()
	t[#t+1] = b .. ' = ' .. a .. '\n'
	a = b
end

print(table.concat(t))


