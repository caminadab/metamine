function componeer(...)
	local fns = {...}
	if #fns == 1 then
		fns = fns[1]
	end

	return function (...)
		local r = {...}
		for i,fn in ipairs(fns) do

			r = {fn(...)}
			if r[1] == nil then return nil end
		end
		return unpack(r)
	end
end

function curry(a,b)
	return nil
end

function map(v, fn, ...)
	local r = {}
	for k,v in pairs(v) do r[k] = fn(v, ...) end
	return r
end

function imap(v, fn, ...)
	local r = {}
	for k,v in ipairs(v) do r[k] = fn(v, ...) end
	return r
end

function imap(v, fn)
	local r = {}
	for k,v in ipairs(v) do r[k] = fn(v) end
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
	['-'] = function(A) if b then return a - b else return a end end;
	['·'] = function(A) return a * b end;
	['/'] = function(A) return a / b end;
	['^'] = function(A) return a ^ b end;

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
