require 'func'
require 'ontleed'
require 'oplos'
require 'doe'

--[[
code
	ontleed
kennis: exp
	deduceer
kennis
	oplos
waarde: exp
	delta
verandering

	plan
planning
	bouw
proces

bereken-strekking
Berekenbaarheid onderscheidt waarden van kennis
]]

--vertaal = componeer(ontleed, [deduceer, oplos, delta)
vertaal = componeer(ontleed, oplos, doe0)

if test then
end
