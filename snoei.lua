
function snoei(stroom)
	local s = {}
	for i,feit in ipairs(stroom) do
		local fn,a,b = feit[1],feit[2],feit[3]
		if fn ~= ':' then
			s[#s+1] = feit
		end
	end
	return s
end
