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

local function recdt(v,p)
	if isexp(v) then
		local f,a,b = v[1],v[2],v[3]
		if f == '=' then
			-- delta b
			local dtb = recdt(b,p) -- [ (0 -> 3) ]
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
			--log("NANI? "..f)
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

function dt(stroom)
	local p = {}
	for i,v in ipairs(stroom) do
		recdt(v,p)
	end
	return p
end

--[[
vertaal = code -> stroom
	ontleed: code -> kennis
	noem: feiten => (naam -> exp)
	sorteer: namen -> stroom

	typeer stroom
	uitrol: stroom -> makkelijke-stroom
]]
function vertaal(code)
	local kennis = ontleed(code)
	if not kennis then return false,'ontleed' end

	-- herleidt alle info
	--local kennis = ontrafel(kennis)
	--local kennis = deduceer(kennis) ; if _G.verboos then print('\n# Kennis\n'..unlisp(kennis)..'\n') end
	--local kennis = ontrafel(kennis)
	
	-- sorteer
	local stroom,fout = sorteer(kennis)
	local stroom = snoei(stroom)

	-- tijd!
	local stroom = dt(stroom)
	log('STROOM',stroom)

	return stroom,fout
end
