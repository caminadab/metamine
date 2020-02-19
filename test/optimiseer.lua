require 'optimiseer'
require 'combineer' require 'ontleed'
require 'util'

local function T(x)
	return combineer(optimiseer(ontleedexp(x)))
end

local a = T "1 + 2"
assert(a == "3", a)

local a = T "1 + a"
assert(a == "1 + a", a)

local a = T "1 - 2 + 3"
assert(a == "2", a)

local a = T "3 · 2 + a"
assert(a == "6 + a", a)

local a = T "√ 9"
assert(a == "3", a)

local a = T "√(1 + a) + √ 9"
assert(a == "√ ((1 + a) + 3)", a)

local a = T "(((1 + 1) + 1) + 1)"
assert(a == "4", a)

local a = T "2 + 3"
assert(a == "5", a)

local a = T "max(2,1)"
assert(a == "2", a)

local a = T "(1 + 1) + (1 + 1)"
assert(a == "4", a)

local a = T "((1 + 1) + 1)"
assert(a == "3", a)

local a = T "((((1 + 1) + 1) + 1) + 1)"
assert(a == "5", a)

local a = T "1 + 1 + 1 + 1"
assert(a == "4", a)

print('alles ok')
