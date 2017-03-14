function equals1(a,...)
	local args = {...}
	for i,arg in ipairs(args) do
		if arg ~= a then
			return false
		end
	end
	return true
end

function fill(orig, with)
	local res = magic()
	
	-- fi
	res.group = {}
	for i=1,#orig.group do res.group[i] = orig.group[i] end
	for i=#orig.group,#with.group do res.group[i] = with.group[i] end

	res.val = {}
	for index,val in all(orig) do
		-- build new index
		local dup = {}
		for i = 1, #orig.group - #with.group do
			dup[i] = index[i]
		end

		table.insert(dup, 1, 'val')

		deepset(res, dup, with.val)
	end
	return res
end

function func(fn, group)
	return function(...)
		local args = {...}
		local magic = magic()

		-- biggest group
		local big = args[1]
		for i=2,#args do
			args[i] = enchant(args[i])
			local arg = args[i]
			if #arg.group > #big.group then
				big = arg
			end
		end
		
		magic.group = copy(big.group)
		magic.group[#magic.group] = group

		-- magical update
		function magic:update()
			for index,val in all(big) do
				local nargs = {}
				local ii = copy(index)
				table.insert(ii, 1, 'val')
				for i=1,#args do
					local ext = fill(big, args[i])
					nargs[i] = deepget(ext, ii)
				end
				local res = fn(table.unpack(nargs))
				deepset(magic, ii, res)
			end
		end

		for i,arg in ipairs(args) do
			triggers(arg, magic)
		end

		return magic
	end
end

equals = func(equals1, 'bool')
