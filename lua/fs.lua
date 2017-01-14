local files = {} -- path -> file

function file(name)
	if files[name] then
		return files[name]
	end
	
	local file = magic()
	file.group = {'text'}
	file.name = 'file://'..name
	file.val = sas.readfile(name)
	file.text = 'file://'..name
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