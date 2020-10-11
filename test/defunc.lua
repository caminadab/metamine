do return end
require 'parse'
require 'defunc'

-- id
local a = X('_arg', '0')
local b = defunc(a, '0')
assert(atom(b) == 'fn.id')

-- kruid R
local a = X('+', '2', X('_arg', '0'))
local b = defunc(a, '0')
print(deparse(a), deparse(b))

-- kruid L
local a = X('+', X('_arg', '0'), '2')
local b = defunc(a, '0')
print(deparse(a), deparse(b))

-- merge
local a = X('+', X('_arg', '1'), X('_arg', '2'))
local b = defunc(a, '0')
print(deparse(a), deparse(b))
