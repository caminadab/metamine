function split1(text, delim)
	local parts = {}
	-- loop
	local offset = 1
	while true do
		local index = string.find(text, delim, offset, false)
		if not index then
			break
		end
		local part = text:sub(offset, index - 1)
		offset = index + #delim
		table.insert(parts, part)
	end
	-- last part (?)
	local last = text:sub(offset)
	table.insert(parts, last)
	local text = '['..#parts..'#]'
	return parts
end


	-- recursively travel through a grouped value tree (______)
function all(magic)
		
	function coall(val, group, level, index)
		val = val or magic.val
		group = group or magic.group
		level = level or 1
		index = index or {}
		
		if level == #group then
			coroutine.yield(index, val)
			return
		end
		
		if val == nil then
			return
		end
		
		if group[level] == 'list' then
			for i = 1, #val do
				index[level] = i
				coall(val[i], group, level + 1, index)
			end
		else
			for k,v in pairs(val) do
				index[level] = k
				coall(val[k], group, level + 1, index)
			end
		end
	end

	
	return coroutine.wrap(coall)
end

function ensure(index, val)
	local cur = val
	for i=1,#index-2 do
		cur[index[i]] = cur[index[i]] or {}
		cur = cur[index[i]]
	end
	return cur,index[#index-1]
end

function deepset(t,keys,v)
	local c = t
	
	-- create tables
	for i=1,#keys-1 do
		key = keys[i]
		c[key] = c[key] or {}
		c = c[key]
	end
	c[keys[#keys]] = v
end

function split(text, delim)
	text = enchant(text)
	delim = enchant(delim)
	
	local parts = magic()
	parts.text = '[...]'
	parts.val = {}
	
	-- group
	if text.group[#text.group] ~= 'text' then
		error('can only split text')
	end
	
	parts.group = {}
	for i=1,#text.group-1 do
		parts.group[i] = text.group[i]
	end
	
	parts.group[#parts.group+1] = 'list'
	parts.group[#parts.group+1] = 'text'
	
	function parts:update()
		for index,val in all(text) do
			local split = split1(val, delim.val)
			table.insert(index, 1, 'val')
			
			print('INDEX', liststring(index))
			deepset(parts, index, split)
			table.remove(index, 1)
		end
	end
	
	triggers(text, parts)
	
	return parts
end

function length(text)
	local len = magic()
	len.group = {'int'}
	len.text = '0#'
	len.val = 0
	
	function len:update()
		len.val = #text.val
		len.text = #text.val..'#'
	end
	triggers(text, len)
	
	return len
end

function lines(data)
	assert(data.group[1] == 'text')
	
	local m = magic()
	
	m.val = {}
	m.text = "0 lines"
	m.group = {"list", "text"}
	
	function m:update()
		local last = 1
		while true do
			local eol = data.val:find("\n", last)
			if not eol then
				break
			end
			m.val[#m.val + 1] = data.val:sub(last, eol)
			last = eol + 1
		end
		m.text = #m.val.." lines"
	end
	triggers(data, m)
	return m
end