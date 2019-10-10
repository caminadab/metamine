require 'graaf'
require 'combineer'
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

-- codegen: focusstroom naar proc
-- focus: exp naar focusstroom
function focus(exp)
	local focusgraaf = maakgraaf()
	local exps = {}

	-- constant(exp) -> init(schepper)
	local function isconstant(exp)
		return not not tostring(atoom(exp))
	end

	local init = waarvoordfs(exp, isconstant)
	local tijd = waarvoordfs(exp, isconstant)

end

