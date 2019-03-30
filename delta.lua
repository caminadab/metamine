require 'exp'
require 'set'

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
	elseif exp.v == 'nu' then
		return set('altijd')
	else
		return set()
	end
end

function delta(exp)
	-- event -> exp
	local map = {}
	for v in boompairsdfs(exp) do
		print(varnaam(v.i), exp2string(v))

		if isatoom(v) then
			map[v] = tijdstip(v)
			print('',exp2string(v), tijdstip(v))
		end
	end

	-- samenvoegen
	for v in boompairsdfs(exp) do
		if not isatoom(v) then
			local set = set()
			for i=1,#v do
				set = unie(set, map[v[i]])
			end
			map[v] = set
		end
	end

	--return { altijd = 
end

	
