--[[
link = server(10101)
file.data = tostring(link.clients.delta)

magic {
	val { ... }
	change { 0.1, MAGIC, file }
	[ delta ]
	group { "text" }
]]