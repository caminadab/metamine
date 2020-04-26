require 'vertaal'
require 'bouw.codegen'
require 'doe'
require 'optimiseer'
require 'combineer' require 'ontleed'
require 'util'

opt = {['0'] = false}

local function T(x)
	local code,err = vertaal("main = "..x)
	for i,msg in ipairs(err) do
		print(fout2ansi(msg))
	end
	return doe(code)
end

-- LINQ
local a = T "Σ 0..10"
assert(a == 45)

local a = T "Σ (0..10) filter (x → (x mod 2 = 0))"
assert(a == 20, a)

local a = T "Σ (0..10) map (-)"
assert(a == -45)

local a = T "Σ (0..10 × 0..10) map (·)"
assert(a == 2025, a)

local a = T "Σ 3..6"
assert(a == 12, a)

local a = T "Σ (0..10) map (√)"
assert(math.floor(a) == 19, a)


local a = T "1 + 2"
assert(a == 3, a)

local a = T "1 - 2 + 3"
assert(a == 2, a)

local a = T "3 · 2 + 8"
assert(a == 14, a)

local a = T "√ 9"
assert(a == 3, a)

local a = T "(((1 + 1) + 1) + 1)"
assert(a == 4, a)

local a = T "2 + 3"
assert(a == 5, a)

local a = T "max(2,1)"
assert(a == 2, a)

local a = T "(1 + 1) + (1 + 1)"
assert(a == 4, a)

local a = T "((1 + 1) + 1)"
assert(a == 3, a)

local a = T "((((1 + 1) + 1) + 1) + 1)"
assert(a == 5, a)

local a = T "1 + 1 + 1 + 1"
assert(a == 4, a)

print('alles ok')
