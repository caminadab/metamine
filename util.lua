function file(name, data)
	if not data then
		local f = io.open(name, 'r')
		data = f:read("*a")
		f:close()
		return data
	else
		local f = io.open(name, 'w')
		f:write(data)
		f:close()
	end
end

