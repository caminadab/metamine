require 'symbool'

function wanneer(exp)
	if tonumber(exp) then
		return 0
	end
	return 0
end

function verenig_tijd(a,b)
	if a == 'start' then b,a = a,b end
	if a == 'start' then return b end
end

function plan(stroom)
	local plan = {} -- tijdstip -> assignments
	for i,eq in ipairs(stroom) do
		local naam,exp = eq[2],eq[3]
		local afh = var(exp)
		local tijdstip = 'start'
		for bron in pairs(afh) do
			local tijdstip = wanneer(bron)
		end
	end
	return plan
end

-- tests
