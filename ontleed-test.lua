require 'ontleed'
require 'exp'

if test then
	local a = ontleed0('a = 10')
	assert(a.fn == '=')
	assert(a[1] == 'a')
	assert(a[2] == '10')

	assert(ontleed0('☆') == '__', ontleed0('☆'))

	local a = toexp(ontleed0('a = b ∧ c = d'))
	assert(a.fn == '/\\')
	assert(a[1].fn == '=')
	assert(a[2][2] == 'd')

	local a = toexp(ontleed0('a = b\nc = d\n'))
	assert(tostring(a) == [[/\(=(a b) =(c d))]], tostring(a))

	local a = toexp(ontleed0('a = [1, 2]'))
	assert(tostring(a) == [[=(a [](1 2))]], tostring(a))

	local a = toexp(ontleed0('a · b² - sin c'))
	assert(tostring(a) == '-(*(a ^(b 2)) sin(c))', tostring(a))

	local a = toexp(ontleed0('f = 1/★'))
	assert(tostring(a) == '=(f /(1 _))', tostring(a))

	local a = toexp(ontleed0('f = ★ + ☆'))
	assert(tostring(a) == '=(f +(_ __))', tostring(a))
	
end
