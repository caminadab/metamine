local files = {} -- path -> file

function infile(path)
	path = enchant(path)
	
	local file = magic()
	
	-- group
	if path.group[#path.group] ~= 'text' then
		error('can only open text paths')
	end
	
	file.group = copy(path.group)
	file.group[#file.group] = 'text'
	
	function file:update()
		for index,val in all(path) do
			local data = sas.readfile(val) or ''
			table.insert(index, 1, 'val')
			
			deepset(file, index, data)
			table.remove(index, 1)
		end
	end
	
	triggers(path, file)
	
	return file
end

function file(name)
	if files[name] then
		return files[name]
	end
	
	local file = magic()
	file.group = {'text'}
	file.name = 'file://'..name
	file.val = sas.readfile(name)
	local data = file.val -- what to write

	-- metamagic
	getmetatable(file).__newindex = function(t,k,v)
		if k == 'data' then
			if v == nil then
				-- delete!
				data = nil
				trigger(file)
			else
				data = enchant(v)
				triggers(data, file)
			end
		else
			rawset(t,k,v)
		end
	end
	
	function file:update()
		if not data then
			-- delete
			sas.deletefile(name)
		elseif self.val ~= data.val then
			if data.group[1] ~= 'text' then
				error('not text')
			end
			self.val = data.val
			sas.writefile(name, self.val)
		end
	end
	
	return file
end