require 'ontleed'
require 'typegraaf'

local g = maaktypegraaf()

local int = g:maaktype('getal')
local getal = g:maaktype('int', 'getal')

assert(g:issubtype(int, getal), '"int" is geen subset van "getal"')
