function plet(exp, ins)
	local ins = ins or {o='[]'}

	if fn(exp) == '_' and atoom(arg0(exp)) == 'fn.merge' then
		local args = arg1(exp)

		if #args == 2 then
			ins[#ins+1] = X'dup'
			plet(args[1], ins)
			ins[#ins+1] = X'rouleer'
			plet(args[2], ins)
			ins[#ins+1] = X'rouleer'

		elseif #args == 3 then
			ins[#ins+1] = X'trip'
			plet(args[1], ins)
			ins[#ins+1] = X'rouleer'
			plet(args[2], ins)
			ins[#ins+1] = X'rouleer'
			plet(args[3], ins)
			ins[#ins+1] = X'rouleer'
		
		else
			error('onbekende hoeveelheid args: '..combineer(exp))
		end

	elseif fn(exp) == '_' and atoom(arg0(exp)) == 'fn.constant' then
		plet(arg1(exp), ins)

	elseif isatoom(exp) then
		ins[#ins+1] = X('push', exp)

	elseif isfn(exp) then
		plet(arg(exp), ins)
		ins[#ins+1] = X(fn(exp))

	elseif isobj(exp) then
		for i, sub in ipairs(exp) do
			plet(sub, ins)
		end

	else
		ins[#ins+1] = X'?'
	end

	return ins
end
