
--[[
*(2 +(3 2)) ->
A  +(3 2)
B  *(2 A)
]]
-- met expliciete linkjes naar 'A', 'B'
-- "plet" je expressie naar een lijst van waarden (autoindexed met "varnaam")
function plet(exp,t)
	local t = t or {}
	if isatoom(exp) then --or exp.fn == '->' then
		return exp
		--t[#t+1] = exp
	end

	local waarde = {}
	for k,v in pairs(exp) do
		if exp.fn.v ~= '->' and exp.fn.v ~= 'javascript' and exp.fn ~= 'lua' then
			waarde[k] = plet(v, t)
		else
			waarde = exp
		end
	end
	t[#t+1] = waarde
	return varnaam(#t),t,varnaam
end

-- 1-gebaseerd
-- 1 t/m 26 zijn A t/m Z
-- daarna AA t/m ZZ
function varnaam(i)
	local l = string.char(string.byte('A') + ((i-1)%26))
	local h = string.char(string.byte('A') + ((i-1)/26) - 1)
	if i <= 26 then
		return l
	else
		return h .. l
	end
end


if test then
	require 'exp'
	local w,t = plet{fn=X'*', {fn=X'+', X'1', X'2'}, X'3'}
	for i,w in ipairs(t) do print(exp2string(w)) end
end
