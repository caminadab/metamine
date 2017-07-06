require 'util'
require 'sexp'
require 'eval'

dbg = require 'debugger'

print("\n",unparse(eval(parse(file(...)))))
