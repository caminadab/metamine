require 'ontleed'
require 'bouw.luagen'
require 'bouw.codegen'
require 'vertaal'

local a = vertaal("app = 1 + 2")

assert(load(luagen(a))() == 3, luagen(a))
