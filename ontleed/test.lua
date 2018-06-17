require 'ontleed'
require 'lisp'

a,err = ontleed('1 + 1 = 2\n3 * 3 = 9')
assert(not err)

a,err = ontleed('a = 2\n\n 3 +')
assert(#err == 1)
