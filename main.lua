require 'sexpr'
require 'builtin'

local src = [[
(
	(:= message
		(||
			(hton (# payload))
			payload
		)
	)
	(:= (. a payload) hoi)
	(:= a message)
	(:= h (hex a))
)
]]

--[[
message := hton #payload  ||  payload
a.payload := 'hoi'
h := hex a
]]



local out = eval(parse(src))
print(unparse(out))