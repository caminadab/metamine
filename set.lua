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

function unie(...)
	local t = {...}
	if #t == 1 then t = t[1] end
	local r = {}
	for i,set in ipairs(t) do
		for v in pairs(set) do
			r[v] = true
		end
	end
end

function cat(...)
	local tt = {...}
	local r = {}
	for i,t in ipairs(tt) do
	log(t)
		for i,v in ipairs(t) do
			r[#r+1] = v
		end
	end
	return r
end
