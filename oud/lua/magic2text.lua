
local function val2text(val, group)
	if not val then
		return '<none>'
	end

	if #group == 1 then
		if group[1] == 'server' then
			return '*'
		elseif group[1] == 'client' then
			return '%'.. val.id
		elseif group[1] == 'number' then
			return tostring(val)
		elseif group[1] == 'bool' then
			return tostring(val)
		elseif group[1] == 'text' then
			local res = string.format('%q', val)
			res = res:gsub('\n', 'n')
			return res
		else
			return '<unknown>'
		end
	end

	-- sequence
	if group[1] == 'list' then
		local res = {'['}
		local subtype = copy(group)
		table.remove(subtype, 1)

		for i,item in pairs(val) do
			table.insert(res, val2text(item, subtype))
			if next(val, i) then
				table.insert(res, ' ')
			end
		end
		table.insert(res, ']')
		return table.concat(res)
	end

	-- collection
	if group[1] == 'set' then
		local res = {'('}
		local subtype = copy(group)
		table.remove(subtype, 1)
		for item in pairs(val) do
			table.insert(res, val2text(item, subtype))
			if next(val, item) then
				table.insert(res, ' ')
			end
		end
		table.insert(res, ')')
		return table.concat(res)
	end
	
	-- dict
	if #group > 1 then
		local res = {'{'}
		local subtype = copy(group)
		local keytype = group[1]
		table.remove(subtype, 1)
		for key,subval in pairs(val) do
			--table.insert(res, val2text(key, keytype))
			table.insert(res, '->')
			table.insert(res, val2text(subval, subtype))
			if next(val, key) then
				table.insert(res, ' ')
			end
		end
		table.insert(res, '}')
		return table.concat(res)
	end


	return '<not implemented>'
end

function group2text(group)
	if #group == 0 then
		return 'none'
	end
	local res = group[#group]
	if res == nil then
		print(debug.traceback())
		return '<ERROR>'
	end
	for i = #group-1, 1, -1 do
		-- list
		if group[i] == 'list' then
			res = '[' .. res .. ']'
			
		-- set
		elseif group[i] == 'set' then
			res = '(' .. res .. ')'
			
		-- dict
		else
			res = '{'..group[i]..'->'..res..'}'
		end
	end
	return res
end

function magic2text(magic)
	local group = group2text(magic.group)
	
	return group ..' '.. val2text(magic.val, magic.group)
end	
