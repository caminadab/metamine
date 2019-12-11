require 'vertaal'
require 'doe'

local app = vertaal "uit = 1 + 2"

assert(doe(app) == 3)
