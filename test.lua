require 'sexp'
require 'eval'
require 'util'

local res = eval(parse(file('test.lisp')))
print(unparse(res))
