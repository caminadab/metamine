require 'flow'
require 'set'

local flow = maakflow()
flow:link(set('a'), 'b')
flow:link(set('b'), 'c')

assert(flow:flowopwaarts('a', 'c'))
