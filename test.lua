#!/usr/bin/lua
require 'sexp'
require 'eval'
require 'util'

local res = eval(parse(file('test.lisp')))
if res == 'true' then
	return
else
	print(unparse(res))
end
return

