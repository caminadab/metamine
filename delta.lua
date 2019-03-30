require 'exp'

function optimiseer(o)
	
end

--[[

uit = "a" || b
nu > 1 ⇒ b = "b"

||(
  [](97) 
  =>(>(nu 1) [](98))
)

"a" || ((nu > 1) ⇒ "b")

tijdstip = start | eerste-seconde


]]

function tijdstip(exp)
	if tonumber(exp.v) then
		return set('start')
	elseif exp.v == 'eerste-seconde' then
		return set('eerste-seconde')
	else
		return set()
	end
end

function delta(exp)
	local p = {}
	for v in boompairs(exp) do
		p[#p+1] = v
		print(varnaam(#p), exp2string(v))

		if isatoom(v) then
			tijdstip(
		end
	end
end
	
