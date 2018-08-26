require 'symbool'

function wanneer(exp)
	if tonumber(exp) then
		return 0
	end
	return 0
end

function plan(stroom)
	local plan = {} -- tijdstip -> assignments
	for i,eq in ipairs(stroom) do
		local naam,args = eq[2],eq[3]
		for naam in pairs(var(eq[3])) do
		end
	end
	return plan
end

-- tests
