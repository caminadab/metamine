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

function deepget(t,keys)
	local c = t
	
	for i=1,#keys do
		local key = keys[i]
		if c[key] == nil then
			return nil
		end
		c = c[key]
	end
	
	return c
end

function deepset(t,keys,v)
	local c = t
	
	-- create tables
	for i=1,#keys-1 do
		local key = keys[i]
		c[key] = c[key] or {}
		c = c[key]
	end
	c[keys[#keys]] = v
end

function split(text, delim)
	text = enchant(text)
	delim = enchant(delim)
	
	local parts = magic()
	
	-- group
	if text.group[#text.group] ~= 'text' then
		error('can only split text')
	end
	
	parts.group = copy(text.group)
	table.insert(parts.group, #parts.group, 'list')
	
	function parts:update()
		for index,val in all(text) do
			local split = split1(val, delim.val)
			table.insert(index, 1, 'val')
			
			deepset(parts, index, split)
			table.remove(index, 1)
		end
	end
	
	triggers(delim, parts)
	triggers(text, parts)
	
	return parts
end

function concat(parts)
	
	local text = magic()
	
	text.group = copy(parts.group)
	table.remove(text.group, #text.group-1)
	
	function text:update()
		for index,val in all(parts) do
			table.insert(index, 1, 'val')
			
			local stump = copy(index)
			table.remove(stump, #stump)
			local l = deepget(parts, stump)
			local t = table.concat(l)
			
			deepset(text, stump, t)
			
			table.remove(index, 1)
		end
	end
	
	triggers(parts, text)
	
	return text
end

-- magic concat
function concat1(a, b)
	local agg = magic()
	
	-- group
	if not equals(a.group, b.group) or a.group[#a.group] ~= 'text' then
		error('mismatching types')
	end
	
	agg.group = copy(text.group)
	
	function agg:update()
		for index,val in all(a) do
			local valA = deepget
			local agg1 = val .. post.val
			table.insert(index, 1, 'val')
			
			deepset(agg, index, agg1)
			table.remove(index, 1)
		end
	end
	
	triggers(text, agg)
	triggers(post, agg)
	
	return agg
end

function append1(text, post)
	text = enchant(text)
	post = enchant(post)
	
	local agg = magic()
	
	-- group
	if text.group[#text.group] ~= 'text' then
		error('can only prepend text')
	end
	
	agg.group = copy(text.group)
	
	function agg:update()
		for index,val in all(text) do
			local agg1 = val .. post.val
			table.insert(index, 1, 'val')
			
			deepset(agg, index, agg1)
			table.remove(index, 1)
		end
	end
	
	triggers(text, agg)
	triggers(post, agg)
	
	return agg
end

function prepend1(text, pre)
	text = enchant(text)
	pre = enchant(pre)
	
	local agg = magic()
	
	-- group
	if text.group[#text.group] ~= 'text' then
		error('can only prepend text')
	end
	
	agg.group = copy(text.group)
	
	function agg:update()
		for index,val in all(text) do
			local agg1 = pre.val .. val
			table.insert(index, 1, 'val')
			
			deepset(agg, index, agg1)
			table.remove(index, 1)
		end
	end
	
	triggers(text, agg)
	triggers(pre, agg)
	
	return agg
end

function totext(num)
	num = enchant(num)
	
	local agg = magic()
	
	-- group
	if num.group[#num.group] ~= 'number' then
		error('can only convert numbers to text')
	end
	
	agg.group = copy(num.group)
	agg.group[#agg.group] = 'text'
	
	function agg:update()
		for index,val in all(num) do
			local agg1 = tostring(val)
			table.insert(index, 1, 'val')
			
			deepset(agg, index, agg1)
			table.remove(index, 1)
		end
	end
	
	triggers(num, agg)
	
	return agg
end


function append(f, ...)
	local tt = {...}
	local f = f
	local agg = magic()
	
	agg.group = copy(f.group)
	
	function agg:update()
		for index,val in all(f) do
			local agg1 = { tostring(val) }
			
			table.insert(index, 1, 'val')
			for i=1,#tt do
				local v = deepget(tt[i], index)
				table.insert(agg1, v)
			end
			agg1 = table.concat(agg1)
			
			
			deepset(agg, index, agg1)
			table.remove(index, 1)
		end
	end
	
	-- trigger
	triggers(f, agg)
	for i=1,#tt do
		triggers(tt[i], agg)
	end
	
	return agg
end



function length(text)
	text = enchant(text)
	
	local agg = magic()
	
	-- group
	if text.group[#text.group] ~= 'text' then
		error('can only get length of text')
	end
	
	agg.group = copy(text.group)
	agg.group[#agg.group] = 'number'
	
	function agg:update()
		for index,val in all(text) do
			local agg1 = #val
			table.insert(index, 1, 'val')
			
			deepset(agg, index, agg1)
			table.remove(index, 1)
		end
	end
	
	triggers(text, agg)
	
	return agg
end
