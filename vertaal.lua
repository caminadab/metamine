require 'util'
require 'lisp'

require 'ontleed'
require 'noem'
require 'typeer'
require 'uitrol'
require 'vhgraaf'
require 'delta'

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

vertaal = componeer(ontleed, sorteer, deltastroom)

if test then
	vertaal('a = 10')
end
