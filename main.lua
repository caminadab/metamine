require 'sexpr'
require 'builtin'
require 'eval'

local src = [[
(
	(:= message
		(||
			(hton (# payload))
			payload
		)
	)
	(:= (. a payload) 'hoi')
	(: a message)
	(:= h (hex a))
)
]]

--[[
message := hton #payload  ||  payload
a.payload := 'hoi'
a := message
h := hex a
]]



local out = eval(parse(src))
print(unparse(out))