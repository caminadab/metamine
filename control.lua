require 'exp'
require 'util'

-- control flow graph builder
function control(exp)
	print(exp2string(exp))
	local fns = {}
	for sub in boompairsdfs(exp) do
		-- _fn(,(0 body))
		if fn(sub) == '_fn' then
			local argnum = atoom(sub[1], 1)
			local waarde = sub[1][2]

			-- verwijder arg
			for subb in boompairsdfs(waarde) do
				if fn(subb) == '_arg' then
					subb.fn = nil
					subb.v = 'arg'
				end
			end

			-- we hebben maar 1 arg nodig nu
			fns[#fns+1] = waarde

			-- fix deze
			sub.fn = nil
			sub.v = 'fn'..#fns
		end
	end

	print()
	for i,fn in ipairs(fns) do
		print('fn'..(i-1)..':')
		print('  '..combineer(fn))
	end
	print()
end

if test then
	require 'lisp'
	local E = ontleedexp

	control(E'_fn(0, _arg(0) + 1 · 3)')
end

