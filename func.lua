function curry(a,b)
	return nil
end

function map(v, fn)
	local r = {}
	for k,v in pairs(v) do r[k] = fn(v) end
	--for k,v in ipairs(v) do r[k] = fn(v) end
	return r
end

function filter(t,fn)
	local r = {}
	for i,v in ipairs(t) do
		if fn(v) then
			r[#r+1] = v
		end
	end
	return r
end

function keerom(t)
	local r = {}
	for i,v in ipairs(t) do
		r[#t-i+1] = v
	end
	return r
end

function setlijst(set)
	local r = {}
	for k in spairs(set) do
		r[#r+1] = k
	end
	return r
end

function union(...)
	local t = {...}
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

function join(a,b)
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

-- past binop toe op alle leden
-- zoals som
function binop(lijst, fn)
	local r = lijst[1]
	for i=2,#lijst do
		r = fn(r, lijst[i])
	end
	return r
end

function staart(lijst)
	local t = {}
	for i=2,#lijst do
		t[i-1] = lijst[i]
	end
	return t
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
