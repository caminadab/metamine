package.path = package.path .. ';../?.lua'
require 'util'
require 'exp'

local maakvar = maakvars()

local n = 1e4
local t = {}

-- voor C
t[#t+1] = '#include <stdio.h>'
t[#t+1] = ''
t[#t+1] = 'int main() {'
t[#t+1] = '\tint v1 = 2;'
t[#t+1] = '\tint v2 = 4;'
t[#t+1] = '\tint v3 = 8;'
t[#t+1] = '\tint v4 = 16;'

for i=5,n do
	t[#t+1] = string.format('\tint v%s = v%s + v%s - v%s + v%s;', i, i-1, i-2, i-3, i-4)
end

t[#t+1] = '\tprintf("%d\\n", v'..n..');'
t[#t+1] = '\treturn 0;'
t[#t+1] = '}'

local code = table.concat(t, '\n')
file('groot.gen.c', code)

-- is 1030159046
