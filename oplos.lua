require 'verenig'

function oplos(exp)
	if exp.fn == [[=]] or exp.fn == [[/\]] then
		local eqs
		if exp.fn == [[=]] then
			eqs = set(exp)
		else
			eqs = set(table.unpack(exp))
		end
		return verenig(eqs)
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
	
end
