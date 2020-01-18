#!/usr/bin/luajit
require 'util'

local bestanden = io.popen('ls test/*.lua')
for bestand in bestanden:lines() do
	print(color.yellow .. bestand .. color.white)
	dofile(bestand)
end
