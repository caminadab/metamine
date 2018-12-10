require 'util'
require 'lisp'

require 'ontleed'
require 'noem'
require 'sorteer'
require 'typeer'
require 'uitrol'
require 'vhgraaf'
require 'ontrafel'
require 'plan'
require 'snoei'
require 'delta'

require 'js'

-- a := b => (start => a = b)
-- (a => b = c) => b = (a => c)
-- a += b => (beeld => a = a' + 1/60)

function sorteer(kennis)
	local kennis = deduceer(kennis)
	local afh,map = berekenbaarheid(kennis)
	local infostroom,fout = afh:sorteer('in', 'uit')

	if not infostroom then
		return false,fout
	end

	-- terugmappen
	local stroom = {}
	for pijl,naar in infostroom:topologisch(map) do
		stroom[#stroom+1] = map[pijl]
	end
	--local beek = ontrafel(stroom)
	return stroom
end

local function recdelta(v,p)
	if isexp(v) then
		local f,a,b = v[1],v[2],v[3]

		-- a = b
		-- =>
		-- start =>
		--   a := b
		if f == '=' then
			-- delta b
			local dtb = recdelta(b,p) -- [ (0 -> 3) ]
			for i,w in ipairs(dtb) do
				-- w : ((-> 0 3))
				w[3] = {':=', a, w[3]} -- (0 -> 3) --> (0 -> (a := 3))
				p[#p+1] = w -- yes!
			end
		elseif f == 'bestand-in' or f == 'udp-in'  then
				--p[#p+1] = {'->', '0', 'open', v} },
				--p[#p+1] = {'->', {'kan-lezen', v}, {'lees', v} }
				p[#p+1] = {'=>', {'=', 'nu', '0'}, {':=', 'v0', v}}
				return {
					{'=>', {'kan-lezen', 'v0'}, {'lees', 'v0'} }
				}
		else
			--p[#p+1] = v
		end
		return {}
	else
		if tonumber(v) then
			return {{'=>', {'=', 'nu', '0'}, v}} -- moment[]
		elseif v == 'std-in' then
			return {{'->', {'kan-lezen', 'stdin'}, {'lees', 'stdin'} }}
		elseif v == 'bestand-in' then
			return {
				{'->', '0', {'open', 'bestand'} },
				{'->', {'kan-lezen', 'bestand'}, {'lees', 'stdin'} }
			}
		else
			return {}
		end
	end
end

function delta2(stroom)
	if not stroom then return nil end
	local p = {}
	for i,v in ipairs(stroom) do
		recdelta(v,p)
	end
	return p
end

function componeer(...)
	local fns = {...}
	if #fns == 1 then
		fns = fns[1]
	end

	return function (...)
		local r = {...}
		for i,fn in ipairs(fns) do
			print('@', i-1, unlisp(r))
			r = table.pack(fn(table.unpack(r)))
			if r[1] == nil then return nil end
		end
		return table.unpack(r)
	end
end

vertaal = componeer(ontleed, sorteer, snoei, deltastroom)--, plan)
