require 'util'

local bestanden = io.popen('ls test/*.lua')
for bestand in bestanden:lines() do
	print(bestand)
	dofile(bestand)
end
