-- gegeven een (benoemde) expressie
-- voeg simpele ops aan asm toe
-- zoals (+ 1 tijd0)
local function ontrafel0(exp,name,asm,g,fn)
	local aname = name
	if g then aname = name .. g end
	local g = g or -1
	g = g + 1
	if atom(exp) then
		asm[#asm+1] = {fn, aname, exp}
	else
		-- subs
		local args = {}
		for i,sub in ipairs(exp) do
			if atom(sub) then
				args[i] = sub
			else
				args[i] = name..g
				g = ontrafel0(sub,name,asm,g)
			end
		end
		-- zelf
		asm[#asm+1] = {'=', aname, args}
	end
	return g
end

-- [(= name exp)] -> [(= name0 fn)]
function ontrafel(flow)
	local asm = {}
	local num = {}
	for i,v in ipairs(flow) do
		local fn,name,exp = v[1],v[2],v[3]
		ontrafel0(exp,name,asm,nil,fn)
	end

	local log = function()end
	log('# Ontrafel')
	for i,v in ipairs(asm) do
		log(v[2],'= '..unlisp(v[3]))
	end
	log()

	return asm
end
