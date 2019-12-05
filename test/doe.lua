require 'vertaal'
require 'doe'

local app = vertaal("uit = 1 + 2")

assert(doe(app) == 3)

local r,f = doe(vertaal [[
; beweegbare cirkel (gebruik pijltjestoetsen)
x := 10
y := 5
als toetsRechts dan x := x' + 0.1 eind
als toetsLinks dan x := x' - 0.1 eind
als toetsOmhoog dan y := y' + 0.1 eind
als toetsOmlaag dan y := y' - 0.1 eind
uit = teken [ cirkel((x,y),1) ]

als muisKlik dan
	x := muisX
	y := muisY
eind
]])
