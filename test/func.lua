local abc = magic()
abc.group = {'list', 'text'}
abc.val = {'a', 'b', 'c'}

local hoi = enchant('hoi')
local hey = enchant('hey')

local two = magic()
two.group = {'number'}
two.val = 2

-- equals
local b1 = equals(hoi, 'hoi')
assert(b1.val == true)
local b2 = equals(hoi, 'hey')
assert(b2.val == false)

local b3 = equals(abc, 'a')
assert(b3.val[1] and not b3.val[2] and not b3.val[3])
