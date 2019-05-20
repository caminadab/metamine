require 'ontleed' require 'exp'

if true or test then
	local a = ontleed('a = 10')
	assert(a.fn == '=')
	assert(a[1] == 'a')
	assert(a[2] == '10')

	assert(ontleed('☆') == '__', ontleed('☆'))

	local a = toexp(ontleed('a = b ∧ c = d'))
	assert(a.fn == '/\\')
	assert(a[1].fn == '=')
	assert(a[2][2] == 'd')

	local a = toexp('a = 10', 'a.code')
	assert(a.loc.bron == 'a.code')

	local a = toexp(ontleed('a = b\nc = d\n'))
	assert(tostring(a) == [[/\(=(a b) =(c d))]], tostring(a))

	local a = toexp(ontleed('a = [1, 2]'))
	assert(tostring(a) == [[=(a [](1 2))]], tostring(a))

	local a = toexp(ontleed('a · b² - sin c'))
	assert(tostring(a) == '-(*(a ^(b 2)) sin(c))', tostring(a))

	local a = toexp(ontleed('f = 1/★'))
	assert(tostring(a) == '=(f /(1 _))', tostring(a))

	local a = toexp(ontleed('f = ★ + ☆'))
	assert(tostring(a) == '=(f +(_ __))', tostring(a))

	local a = toexp(ontleed('[b₀, b₁]'))
	assert(tostring(a) == '[](b(0) b(1))', tostring(a))

	local a = toexp(ontleed('f⁻¹'))
	assert(tostring(a) == 'inverteer(f)', tostring(a))

	local c = [[
f = ★/2 ∘ sin
a = f⁻¹(2)
	]]
	local s = tostring(toexp(ontleed(c)))
	assert(s == [[/\(=(f @(/(_ 2) sin)) =(a (inverteer(f))(2)))]], s)

	-- lol
	-- 	f = ★/2 ∘ sin
	--	a = f⁻¹(2)
	-- =>
	--	a = (sin⁻¹ ∘ ★·2)  ; a = x → sin⁻¹(x)·2


	local s = tostring(toexp(ontleed('standaarduitvoer = "hoi" || [10]')))
	assert(s == [[=(standaarduitvoer ||([](104 111 105) [](10)))]], s)

	local s = tostring(toexp(ontleed('a = (f^1000) (3)')))
	assert(s == [[=(a (^(f 1000))(3))]], s)
end
