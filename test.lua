#!/usr/bin/lua
package.path = package.path .. ';bin/?.lua'
test = true
--verboos = true

require0 = require
require = function(n)
	--print('TESTING', n)
	return require0(n)
end

local bestanden = io.popen('ls *.lua')
for bestand in bestanden:lines() do
	local kort = bestand:sub(1,-5)
	require(kort)
end