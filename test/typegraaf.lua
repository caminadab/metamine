require 'typegraaf'
require 'rapport'
require 'ontleed'
require 'util'


local g = maaktypegraaf()

local int = g:maaktype('getal')
local getal = g:maaktype('int', 'getal')

if not g:issubtype(int, getal) then
	print('"int" is geen subset van "getal"))')
	file('graaf.html', graaf2html(g))
end
