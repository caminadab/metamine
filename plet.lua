require 'exp'

function plet1(exp, ins)
	if isatoom(exp) then
		ins[#ins+1] = X('push', exp)
	
	elseif isobj(exp) then
		for i,sub in ipairs(exp) do
			ins[#ins+1] = X('push', exp)
		end

		if obj(exp) ~= ',' then
			ins[#ins+1] = X(obj(exp), tostring(#exp))
		end

	end
end

function plet(exp, ins)
	local ins = ins or {o='[]'}

	if fn(exp) == 'fn.merge' then
		local len = #arg(exp)
		ins[#ins+1] = X('rep', tostring(len))
		for i,sub in ipairs(arg(exp)) do
			plet(sub, ins)
			ins[#ins+1] = X('wissel', tostring(-i))
		end

	elseif isobj(exp) then
		for i,sub in ipairs(exp) do
			plet(sub, ins)
		end

	elseif isfn(exp) and fn(exp):sub(1,3) == "fn." then
		plet1(arg(exp), ins)
		ins[#ins+1] = X(fn(exp):sub(4))

	elseif fn(exp) == '∘' then
		plet(arg(exp), ins)

	elseif isatoom(exp) then
		ins[#ins+1] = exp
	end
	
	return ins
end
