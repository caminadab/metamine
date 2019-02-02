require 'verenig'

function oplos(exp)
	-- sets van vergelijkingen
	if exp.fn == [[=]] or exp.fn == [[/\]] then
		local eqs
		if exp.fn == [[=]] then
			eqs = set(exp)
		else
			eqs = set(table.unpack(exp))
		end
		local function isinvoer(val)
			return tonumber(val) or val == '_'
		end
		return verenig(eqs, isinvoer)
	end
	return exp
end

if test then
	require 'util'
	require 'ontleed'

	assert(oplos(ontleed0('a = 2')).a == '2')

	-- b = 2 + 2
	local v = oplos(ontleed0('a = 2\na + 2 = b'))
	assert(v)
	assert(tostring(v.b) == '+(2 2)',
		'v.b = '..tostring(v.b)..' ≠ +(2 2)')

	local v = oplos(ontleed0('f(a) = f(b)\na = 2'))
	assert(v)
	assert(tostring(v.b) == '2',
		'v.b = '..tostring(v.b)..' ≠ 2')

	local v = oplos(toexp(ontleed0('f(a + 1) = f(b + 1)\na = 2')))
	assert(v)
	assert(tostring(v.b) == '2',
		'v.b = '..tostring(v.b)..' ≠ 2')

	local v = oplos(toexp(ontleed0('f = g⁻¹ ∧ g = ★ - 3')))
	print(toexp(ontleed0('f = g⁻¹ ∧ g = ★ - 3')))
	assert(v)
	assert(tostring(v.f) == 'inverteer(-(_ 3))', tostring(v.f))

	local s = [[
f = ★/2 ∘ sin
a = f⁻¹(2)
	]]
	local c = oplos(toexp(ontleed0(s)))

	for i=1,10 do
		local s = [[
standaarduitvoer = "a = " || tekst(a) || [10]
a = f(3)
f = sin ∘ cos
		]]
		local m = oplos(toexp(ontleed0(s)))
		assert(m.standaarduitvoer)
	end

end
