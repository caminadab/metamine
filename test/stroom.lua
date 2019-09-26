require 'stroom'
require 'set'

local stroom = maakstroom()
stroom:link(set('a'), 'b')
stroom:link(set('b'), 'c')

assert(stroom:stroomopwaarts('a', 'c'))
