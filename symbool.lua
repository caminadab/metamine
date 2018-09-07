function isvar(name)
	if not isatoom(name) then
		return false
	end
	if tonumber(name) then
		return false
	elseif string.upper(name) == name then
		return false
	end
	return true
end

function var(exp,t)
	local t = t or {}
	if atom(exp) then
		if isvar(exp) then
			t[exp] = true
		end
	else
		for i,s in ipairs(exp) do
			var(s,t)
		end
	end
	return t
end

function isatoom(exp)
	return type(exp) ~= 'table'
end

function isexp(exp)
	return type(exp) == 'table'
end
