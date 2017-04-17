local abc = magic()
abc.group = {'list', 'text'}
abc.val = {'a', 'b', 'c'}

local hoi = magic()
hoi.group = {'text'}
hoi.val = 'hoi'
local hey = magic()
hey.group = {'text'}
hey.val = 'hey'

local two = magic()
two.group = {'number'}
two.val = 2

-- append
local hh = append(hoi, hey)
assert(hh.val == 'hoihey')

-- concat
local a = concat(abc)
assert(a.val == 'abc')

-- split
local hy = split(hey, 'e')
assert(hy.val[1] == 'h' and hy.val[2] == 'y')

-- length
local len = length(hoi)
assert(len.val == 3)

-- totext
local t = totext(two)
assert(t.val == '2')
