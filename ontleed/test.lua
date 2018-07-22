require 'ontleed'
require 'lisp'

local a,err = ontleed('*')
assert(err)

local a,err = ontleed('a = 2\nb = 3')
assert(not err)

local a,err = ontleed('a * 2 = 3\na - 4 = b / 8 ^ 3')
assert(not err)

local a,err = ontleed('a = 2\n\n 3 +')
assert(err)

assert(unlisp(ontleed('f = a + b')), '((= f (+ a b)))')

-- functies
assert(unlisp(ontleed('f = a + b')) == '((= f (+ a b)))')
assert(unlisp(ontleed('f = a -> a')) == '((= f (-> a a)))')
assert(unlisp(ontleed('f = a -> a + 1')) == '((= f (-> a (+ a 1))))')

assert(unlisp(ontleed('b = f(a)')) == '((= b (f a)))')
assert(unlisp(ontleed('a : b')) == '((: a b))')
