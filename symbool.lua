
function isvar(name)
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

