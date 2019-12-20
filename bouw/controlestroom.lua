
--[[
x := 0
dx := 1

als toets.spatie dan
	dx := 0
eind

x += dx
uit = x

init
| (0, 1)
|
| als toets.spatie
| | (x, 0)
|
| itereer
| | (x + dx, dx)
|
exit



c = controlestroom "uit = 1"
print (c)

]]


-- [(0,1), 
function controlestroom(exp)
	local a = 
	
