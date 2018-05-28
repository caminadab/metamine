require 'ontleed'
require 'lisp'

a,err = ontleed('1 + 1 = 2\n3 * 3 = 9')
print(unlisp(a))
