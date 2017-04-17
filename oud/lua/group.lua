function copy(group)
	local copy = {}
	for i=1,#group do
		copy[i] = group[i]
	end
	return copy
end

function equals(a, b)
	if #a ~= #b then
		return false
	end
	
	for i=1,#a do
		if a[i] ~= b[i] then
			return false
		end
	end
	
	return true
end

function name(m)
	for k,v in pairs(_G) do
		if m == v then
			return k
		end
	end
	return 'unknown'
end

--[[
[list text] -> [text]
[socket list text] -> [socket text]
]]
function indexed(parent, key)
	local child = magic()
	child.val = {}
	
	-- {id->[text]} wordt {id->text}
	if #parent.group < 2 then
		error(tostring(key)..' is not a group')
	end
	child.group = copy(parent.group)
	table.remove(child.group, #child.group-1)
	
	function child:update()
		child.val = nil
		for index,val in all(parent) do
			-- filtered group
			if index[#index] == key then
				local alt = copy(index)
				table.remove(alt, #alt)
				table.insert(alt, 1, 'val')
				deepset(child, alt, val)
			end
		end
	end
	
	triggers(parent, child)
	
	return child
end
