function map(v, fn)
	local r = {}
	for k,v in pairs(v) do r[k] = fn(v) end
	--for k,v in ipairs(v) do r[k] = fn(v) end
	return r
end

function reverse(t)
	local r = {}
	for i,v in ipairs(t) do
		r[#t-i+1] = v
	end
	return r
end

function cat(a,b)
	local r = {}
	for i,v in ipairs(a) do
		for i,v in ipairs(v) do
			r[#r+1] = v
		end
		if b then
			r[#r+1] = b
		end
	end
	return r
end

func = {
	['+'] = function(a,b) return a + b end;
	['-'] = function(a,b) if b then return a - b else return a end end;
	['*'] = function(a,b) return a * b end;
	['/'] = function(a,b) return a / b end;
	['^'] = function(a,b) return a ^ b end;
	['[]'] = function(...) return table.pack(...) end;

	['..'] = function(a,b)
		local t = {}
		for i,v in ipairs(a) do t[#t+1] = v end
		for i,v in ipairs(b) do t[#t+1] = v end
		return t
	end;

	-- lib
	['cat'] = cat;

	['split'] = function(a,b)
		local r = {}
		local t = {}
		for i,v in ipairs(a) do
			if v == b then
				r[#r+1] = t
				t = {}
			else
				t[#t+1] = v
			end
		end
		return r
	end;
}
