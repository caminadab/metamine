function file(name)
	local file = {
		name = name,
		modus = 'unknown',
	}
	
	setmetatable(file, {
		__newindex = file_
end