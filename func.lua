function map(v, fn)
	local r = {}
	for k,v in pairs(v) do r[k] = fn(v) end
	for k,v in ipairs(v) do r[k] = fn(v) end
	return r
end

function reverse(t)
	local r = {}
	for i,v in ipairs(t) do
		r[#t-i+1] = v
	end
	return r
end

