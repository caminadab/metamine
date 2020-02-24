require 'combineer'
require 'ontleed'
require 'typeer'
require 'fout'

function moettypezijn(code, typecode)
	local moettype = ontleedexp(typecode)
	local type,fouten = typeer(ontleedexp(code))
	local istype = type

	if moes(istype) ~= moes(moettype) then
		print(string.format('type van "%s" is "%s" maar moet "%s" zijn',
			code, combineer(istype), combineer(moettype)))
		print('typefouten:')
		if #fouten > 0 then
			for i,fout in ipairs(fouten) do
				print(fout2ansi(fout))
			end
		end
		--assert(false)
	end
	return fouten
end

moettypezijn('1 + 2', 'getal')

-- begin makkelijk
moettypezijn('0', 'int')
moettypezijn('1.5', 'getal')
moettypezijn('sin', 'getal → getal')

moettypezijn('a + b', 'getal')
moettypezijn('a ∧ b', 'bit')

moettypezijn('x → x', 'iets → iets')
moettypezijn('x → x + 1', 'getal → getal')
--moettypezijn('[1,2,3] vouw (+)', 'getal')


-- kijk of exp's gelijk worden
local exp = ontleedexp('a = a')
local _,fouten,types = typeer(exp)
assert(types[arg0(exp)] == types[arg1(exp)])

local exp = ontleedexp('a = a + 1')
local _,fouten,types = typeer(exp)
assert(types[arg0(exp)] == types[arg0(arg1(exp))])

local exp = ontleedexp('a → a')
local _,fouten,types = typeer(exp)
assert(types[arg0(exp)] == types[arg1(exp)])

local exp = ontleedexp('x → x + 1')
local _,fouten,types = typeer(exp)
assert(types[arg0(exp)] == types[arg0(arg1(exp))])


-- func
moettypezijn('x → x', 'iets → iets')
moettypezijn('x → x + 1', 'getal → getal')
moettypezijn('sin ∘ cos', 'getal → getal')
moettypezijn('sin 3', 'getal')

-- moeilijke lijsten
moettypezijn('[1,2,3] || [4,5,6]', 'nat → int')
moettypezijn('[1, 2, 0.5] || [1]', 'nat → getal')


-- compositiefout check
local type,fouten = typeer(ontleed[[
f = x → x + 1
g = a, b → a + b
uit = (f ∘ g)(3)
]])
assert(#fouten > 0, C(type)) 

-- tekst types
moettypezijn('"hoi"', 'nat → letter')
local fouten = moettypezijn(' "hoi" || "ja" ', 'nat → letter')
if #fouten > 0 then
	print('\n' .. table.concat(map(fouten, fout2ansi), '\n'))
end



-- foutjes
local t,f = typeer(ontleed([[
w = 177.78
h = 100
spelerW = 5
spelerH = 20
midden = (spelerH + h) / 2
linksY := 0
rechtsY := 0

links = rechthoek((0,linksY'),(spelerW,linksY'+spelerH))
rechts = rechthoek((w-spelerW,rechtsY'),(w,rechtsY'+spelerH))
uit = teken [links, rechts]
]]))


-- functie type mismatch
local t,f = typeer(ontleed([[
uit = f(3)
f = sin
f = cirkel
]]))
assert(#f > 0, 'geen typefouten in ongeldig programma!')

local t,f,types = typeer(ontleed([[
uit = a + b
a = (1,2)
b = (3,4)
]]))
assert(#f == 0, 'fouten maar moest niet')

-- vouw mismatch
local t,f = typeer(ontleed([[
L = [1, 2, 3]
uit = (L vouw (>))
]]))
if #f == 0 then
	print 'geen typefouten in ongeldig programma!'
end
