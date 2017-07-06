require 'util'
require 'sexp'
require 'eval'

dbg = require 'debugger'

print(unparse(eval(parse(file(...)))))
