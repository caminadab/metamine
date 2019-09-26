require 'typegraaf'
require 'rapport'
require 'ontleed'
require 'util'
require 'typeer'

local g = maaktypegraaf()
linkbieb(g)

local int = g:maaktype('getal', 'iets')
local getal = g:maaktype('int', 'getal')
assert(int)

if not g:issubtype(int, getal) then
	print('"int" is geen subset van "getal"')
	file('graaf.html', graaf2html(g.graaf, 'int : getal : iets'))
	os.execute('firefox graaf.html')
end
