require 'ontleed'
require 'lisp'

local a,err = ontleed('*')
do return end

local a,err = ontleed('1 + 1 = 2\n3 * 3 = 9')
assert(not err, unlisp(err))

local a,err = ontleed('a = 2\n\n 3 +')
assert(err and #err == 1, unlisp(a))

-- functies
local a,err = ontleed('f = x -> x')
assert(unlisp(a) == '(= f (-> x x))', unlisp(a))
