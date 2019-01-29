require 'ontleed'
require 'exp'

if test then
	local a = ontleed0('a = 10')
	assert(a.fn == '=')
	assert(a[1] == 'a')
	assert(a[2] == '10')

	local a = toexp(ontleed0('a = b ∧ c = d'))
	print(expmt.__tostring(a))
	assert(a.fn == '/\\')
	assert(a[1].fn == '=')
	assert(a[2][2] == 'd')

	local a = toexp(ontleed0('a = b\nc = d\n'))
	assert(tostring(a) == [[/\(=(a b) =(c d))]], tostring(a))

	local a = toexp(ontleed0('a = [1, 2]'))
	assert(tostring(a) == [[=(a [](1 2))]], tostring(a))
end
