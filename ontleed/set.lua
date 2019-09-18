function set(...)
	local list = {...}
	local s = {}
	for i,v in ipairs(list) do
		s[v] = true
	end
	setmetatable(s, {
		__call = function(s,x) return s[x] end;
		__tostring = function(s)
			local t = { '{' }
			for val in spairs(s) do
				t[#t+1] = tostring(val)
				t[#t+1] = ','
			end
			if t[#t] == ',' then
				t[#t] = nil
			end
			t[#t+1] = '}'
			return table.concat(t)
		end;
	})
	return s
end

function verschil(a,b)
	local s = set()
	for k,v in pairs(a) do
		if not b[k] then
			s[k] = val
		end
	end
	return s
end

function unie(...)
	local t = {...}
	if #t == 1 then t = t[1] end
	local r = set()
	for i,set in ipairs(t) do
		for v in pairs(set) do
			r[v] = true
		end
	end
	return r
end

function complement(a, b)
	local s = {}
	for v in pairs(a) do
		if not b[v] then
			s[v] = true
		end
	end
	return s
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

