function count1(coll)
	local count = 0
	for i in pairs(coll) do
		count = count + 1
	end
	return count
end

function count(coll)
	
	local agg = magic()
	
	-- group
	if #coll.group < 2 then
		error('can only count collections')
	end
	
	-- (*) -> number
	agg.group = copy(coll.group)
	table.remove(agg.group, #agg.group)
	agg.group[#agg.group] = 'number'
	
	
	function agg:update()
		for index,val in all(coll) do
			table.insert(index, 1, 'val')
			
			local stump = copy(index)
			table.remove(stump, #stump)
			local l = deepget(coll, stump)
			local t = count1(l)
			
			deepset(agg, stump, t)
			print('COUNT = '..t)
			
			table.remove(index, 1)
		end
	end
	triggers(coll, agg)
	
	return agg
end

function sum1(coll)
	local sum = 0
	for i,v in pairs(coll) do
		sum = sum + v
	end
	return sum
end

function sum(coll)
	local agg = magic()
	
	-- group
	if #coll.group < 2 then
		error('can only sum collections')
	end
	if coll.group[#coll.group] ~= 'number' then
		error('can only sum numbers')
	end
	
	-- (*) -> number
	agg.group = copy(coll.group)
	table.remove(agg.group, #agg.group)
	agg.group[#agg.group] = 'number'
	
	
	function agg:update()
		for index,val in all(coll) do
			table.insert(index, 1, 'val')
			
			local stump = copy(index)
			table.remove(stump, #stump)
			local l = deepget(coll, stump)
			local t = sum1(l)
			
			deepset(agg, stump, t)
			print('SUM = '..t)
			
			table.remove(index, 1)
		end
	end
	triggers(coll, agg)
	
	return agg
end
