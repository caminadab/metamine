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
	res.group = copy(orig.group)

	res.val = {}
	for index,val in all(orig) do
		-- build new index
		local dup = {}
		for i = 1, #orig.group - #with.group do
			dup[i] = orig.group[i]
		end

		table.insert(dup, 1, 'val')

		deepset(res, dup, with)

		print('res.group=', group2text(res.group))
		print('orig=', orig)
		print('dup=', table.unpack(dup))
		print('with=', with)
		print(to_string(res))
		print('res=', res)
	end
	print('NAIS', group2text(res.group))
	print('res '..tostring(res))
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
				for i=1,#args do
					local ext = fill(big, args[i])
					nargs[i] = deepget(ext, index)
					print('GOT',nargs[i])
				end
				local res = fn(nargs)
				deepset(magic, index, res)
			end
		end

		for i,arg in ipairs(args) do
			print(#arg.group, #magic.group)
			triggers(arg, magic)
		end

		return magic
	end
end

equals = func(equals1, 'bool')
