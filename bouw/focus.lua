require 'graaf'
require 'combineer'
require 'bieb'
require 'exp'

function waarvoordfs(exp, fn)
	local res = {}
	local function r(exp)
		for k,sub in subs(exp) do	
			r(sub)
		end
		if fn(exp) then
			res[#res+1] = exp
		end
	end
	r(exp)
	return res
end

local bieb = bieb()

-- codegen: focusstroom naar proc
-- focus: exp naar focusstroom
--  focusstroom : stroom(focus)
--    focus; lijst(exp)
function focus(exp)
	local focusgraaf = maakgraaf()
	local exps = {}

	-- constant(exp) -> init(schepper)
	local function isconstant(exp)
		if tonumber(atoom(exp)) or bieb[atoom(exp)] then
			exp.constant = true
			return true
		end
		local constant = false
		for k,sub in subs(exp) do
			if sub.constant then
				constant = true
			else
				constant = false
				break
			end
		end
		exp.constant = constant
		return constant
	end


	local init = waarvoordfs(exp, isconstant)
	--local tijd = waarvoordfs(exp, muis)

	for i,v in ipairs(init) do
		print(combineer(v))
	end

	return init
end

