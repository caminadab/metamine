function verschil(a,b)
	local s = {}
	for k,v in pairs(a) do
		print(k,v)
		if not b[k] then
			print('ja')
			s[k] = val
		end
	end
	return s
end

function unie(a,b)
	local t = {}
	for k,v in pairs(a) do t[k] = v end
	for k,v in pairs(b) do t[k] = v end
	return t
end
