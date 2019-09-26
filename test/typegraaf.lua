require 'ontleed'
require 'typegraaf'
require 'typeer'

local g = maaktypegraaf()

local int = g:maaktype('getal', 'iets')
local getal = g:maaktype('int', 'getal')

assert(g:issubtype(int, getal), '"int" is geen subset van "getal"\n'..tostring(g))
