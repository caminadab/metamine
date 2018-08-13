require 'symbool'

function wanneer(exp)
	if tonumber(exp) then
		return 0
	elseif exp == 'toets-'

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
require 'lisp'
assert(plan(lisp('a = 3'))[0])
