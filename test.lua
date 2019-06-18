#!/usr/bin/lua
package.path = package.path .. ';bin/?.lua'
test = true
--verboos = true

--[[
require0 = require
require = function(n)
	print('TESTING', n)
	return require0(n)
end
]]

local bestanden = io.popen('ls *.lua ; ls bouw/*.lua')
local gehad = {test=true}
for bestand in bestanden:lines() do
	local kort = bestand:sub(1,-5)
	gehad[kort] = true
	io.write(kort, ':\t')
	io.flush()
	if kort ~= 'test' then
		require(kort)
	end
	io.write(ansi.regelbegin)
	io.write(ansi.wisregel)
	io.flush()
end
print("KLAAR!")
