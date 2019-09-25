require 'combineer'
require 'ontleed'
require 'typeer'
require 'fout'

function moettypezijn(code, typecode)
	local moettype = typecode
	local type,fouten = typeer(ontleedexp(code))
	if #fouten > 0 then
		for i,fout in ipairs(fouten) do
			print(fout2ansi(fout))
		end
		error('typefouten gevonden')
	end
	local istype = combineer(type)

	assert(istype == moettype, string.format('type van "%s" is "%s" maar moet "%s" zijn',
			code, istype, moettype))
end

moettypezijn('x → x + 1', 'getal → getal')
do return end

-- begin makkelijk
moettypezijn('0', 'int')
moettypezijn('1.5', 'getal')
moettypezijn('sin', 'getal → getal')

moettypezijn('a + a', 'getal')
moettypezijn('a ∧ a', 'bit')


-- kijk of exp's gelijk worden
local exp = ontleedexp('a = a')
local _,fouten,types = typeer(exp)
assert(types[a(exp)] == types[b(exp)])
assert(#fouten == 0)

local exp = ontleedexp('a = a + 1')
local _,fouten,types = typeer(exp)
assert(types[a(exp)] == types[a(b(exp))])
assert(#fouten == 0)

local exp = ontleedexp('a → a')
local _,fouten,types = typeer(exp)
assert(types[a(exp)] == types[b(exp)])
assert(#fouten == 0)

local exp = ontleedexp('x → x + 1')
local _,fouten,types = typeer(exp)
assert(types[a(exp)] == types[a(b(exp))])
assert(#fouten == 0)


-- func
moettypezijn('x → x', 'iets → iets')
moettypezijn('x → x + 1', 'getal → getal')
moettypezijn('sin ∘ cos', 'getal → getal')
moettypezijn('sin 3', 'getal')
