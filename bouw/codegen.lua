require 'exp'
require 'combineer'

function codegen(exp, ins)
	local ins = ins or {o='[]'}

	if fn(exp) == '_' and atoom(arg0(exp)) == 'fn.merge' then
		local args = arg1(exp)

		if #args == 2 then
			ins[#ins+1] = X'dup'
			codegen(args[1], ins)
			ins[#ins+1] = X'rouleer'
			codegen(args[2], ins)
			ins[#ins+1] = X'rouleer'

		elseif #args == 3 then
			ins[#ins+1] = X'trip'
			codegen(args[1], ins)
			ins[#ins+1] = X'rouleer'
			codegen(args[2], ins)
			ins[#ins+1] = X'rouleer'
			codegen(args[3], ins)
			ins[#ins+1] = X'rouleer'
		
		else
			ins[#ins+1] = X('rep', #args)
			for i, arg in ipairs(args) do
				ins[#ins+1] = X'rouleer'
				codegen(arg, ins)
			end
		end

	elseif fn(exp) == '_' and atoom(arg0(exp)) == 'fn.constant' then
		codegen(arg1(exp), ins)

	elseif isatoom(exp) then
		ins[#ins+1] = X('push', exp)

	elseif isfn(exp) then
		codegen(arg(exp), ins)
		ins[#ins+1] = X(fn(exp))

	elseif isobj(exp) then
		for i, sub in ipairs(exp) do
			codegen(sub, ins)
		end

	else
		ins[#ins+1] = X'?'
	end

	return ins
end
