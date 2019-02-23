
--[[
*(2 +(3 2)) ->
A  +(3 2)
B  *(2 A)
]]
-- met expliciete linkjes naar 'A', 'B'
function plet(exp,t)
	local t = t or {}
	if isatoom(exp) then
		return exp
		--t[#t+1] = exp
	end

	-- 1-gebaseerd
	-- 1 t/m 26 zijn A t/m Z
	-- daarna AA t/m ZZ
	function naam(i)
		local l = string.char(string.byte('A') + ((i-1)%26))
		local h = string.char(string.byte('A') + ((i-1)/26) - 1)
		if i <= 26 then
			return l
		else
			return h .. l
		end
	end

	local waarde = {}
	for k,v in pairs(exp) do
		waarde[k] = plet(v, t)
	end
	t[#t+1] = waarde
	return naam(#t),t,naam
end

if test then
	require 'exp'
	local w,t = plet{fn='*', {fn='+', '1', '2'}, '3'}
	for i,w in ipairs(t) do print(toexp(w)) end
end
