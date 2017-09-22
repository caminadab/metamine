local unpack = table.unpack

function compose(...)
	local funcs = {...}
	return function(...)
		local res = {...}
		for i=#funcs,1,-1 do
			local func = funcs[i]
			res = {func(unpack(res))}
		end
		return unpack(res)
	end
end
