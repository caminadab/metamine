#!/usr/bin/luajit
package.path = package.path .. ';bin/?.lua'
require 'util'
test = true
--verboos = true

local require0 = require
require = function(kort)
	io.write(ansi.regelbegin)
	io.write(ansi.wisregel)
	io.write(kort, ':\t')
	io.flush()
	local r
	if kort ~= 'test' then
		r = require0(kort)
	end
	return r
end

local bestanden = io.popen('ls *.lua ; ls bouw/*.lua')
local gehad = {test=true}
for bestand in bestanden:lines() do
	local kort = bestand:sub(1,-5)
	require(kort)
end
print("KLAAR!")
