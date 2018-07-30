require 'ontleed'
require 'lisp'

local function asserto(code,doel)
	local doel = unlisp(lisp(doel))
	local res = unlisp(ontleed(code))
	assert(res == doel, res..' maar moet zijn '..doel)
	return unlisp(ontleed(code))
end


asserto('a > 0 = b', '((= (> a 0) b))') --!

local a,err = ontleed('*')
assert(err)

local a,err = ontleed('a = 2\nb = 3')
assert(not err)

local a,err = ontleed('a * 2 = 3\na - 4 = b / 8 ^ 3')
assert(not err)

local a,err = ontleed('a = 2\n\n 3 +')
assert(err)


-- functies
asserto('f = a + b', '((= f (+ a b)))')
asserto('f = a -> a', '((= f (-> a a)))')
asserto('f = a -> a + 1', '((= f (-> a (+ a 1))))')
asserto('b = f(a)', '((= b (f a)))')
asserto('b = f a', '((= b (f a)))')
--asserto('b = sin a + 1', '((= b (+ (sin a) 1)))')
--[=[asserto([[
f = a -> b
	a: int
	a * 2 = b * 3
]],[[
(
	(= b
		(
			(-> a b)
			(
				(: a int)
				(= (* a 2) (* b 3))
			)
		)
	)
)
]])
]=]
asserto('a = (p => b)', '((= a (=> p b)))')
--asserto("a := 10", "((:= a 10))")
--asserto("a(nu) = a net + 3", "((= (a nu) (+ (a net) 3)))")
asserto("a = b of c", "((= a (of b c))")
--asserto("a = b noch c", "((= a (noch b c))")
--asserto("eerst = (tijd < 1 => [320,240])", "a")
--asserto("a' = 10", "((= (' a) 10))")

--asserto('a : b', '((: a b))')
--
print('KLAAR')
