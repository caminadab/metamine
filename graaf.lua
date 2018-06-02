local function link(graaf,a,b)
	graaf.punten[a] = true
	graaf.punten[b] = true

	graaf.van[a] = graaf.van[a] or {}
	graaf.naar[b] = graaf.naar[b] or {}

	--insert(graaf.randen, {a,b})
	graaf.van[a][b] = true
	graaf.naar[b][a] = true
end

local function ontlink(graaf,a,b)
	graaf.van[a][b] = false
	graaf.naar[b][a] =  false

	if not next(graaf.van[a]) and not next(graaf.naar[a]) then graaf.punten[a] = false end
	if not next(graaf.van[b]) and not next(graaf.naar[b]) then graaf.punten[b] = false end
end

local function bevat(graaf,a,b)
	return graaf.van[a] and graaf.van[a][b]
end

function hascycles(graph)
	local index = 1
	local s = {}
	local strong = {}
	local cycle = false

	function strongconnect(v)
		v.index = index
		v.lowlink = index
		index = index + 1
		s[#s+1] = v
		v.onstack = true

		for n,w in pairs(v.to) do
			if not w.index then
				strongconnect(w)
				v.lowlink = math.min(v.lowlink, w.lowlink)
			elseif w.onstack then
				v.lowlink = math.min(v.lowlink, w.index)
			end
		end

		if v.lowlink == v.index then
			local st = {}
			local w
			repeat
				w = s[#s]
				s[#s] = nil
				w.onstack = false
				st[#st+1] = w.name
			until w == v
			if #st > 1 then
				cycle = true
			end
		end
	end

	for n,v in pairs(graph) do
		v.index,v.lowlink,v.onstack = nil,nil,false
	end

	for n,v in pairs(graph) do
			if not v.index then
			strongconnect(v)
		end
	end

	return cycle
end

function graaf()
	local punten = {}
	local randen = {}
	return {
		punten, randen;
		punten = punten,
		randen = randen,
		van = {}, naar = {};
		link = link,
		ontlink = ontlink,
		cyclisch = cyclisch,
		bevat = bevat,
	}
end

-- test
local a = graaf()
a:link('a', 'b')
assert(not a:cyclisch())
a:link('b', 'a')
assert(a:cyclisch())
