-- herschrijft vergelijkingen
function deduceer(kennis)
	if kennis.fn ~= '&' then
		kennis = {kennis}
	end

	local f = {}

	-- constanten
	for c in pairs(val(feiten)) do
		if tonumber(c) then
			f[#f+1] = {':', c, 'getal'}
		end
	end

	-- vglen herschrijven
	for i,feit in ipairs(feiten) do
		for naam in pairs(var(feit)) do
			local dfeit = isoleer(feit, naam)
			if dfeit then
				f[#f+1] = dfeit
			end
		end
	end

	-- extra toevoegen
	f[#f+1] = {':', 'getal', 'in'}
	f[#f+1] = {':', 'std-uit', 'uit'}
	f[#f+1] = {':', 'std-in', 'in'}
	f[#f+1] = {':', 'cat', 'in'}
	f[#f+1] = {':', 'unie', 'in'}

	f[#f+1] = {':', 'udp-in', 'in'}
	f[#f+1] = {':', 'udp-uit', 'uit'}

	--[[
	f[#f+1] = {':', 'sin', 'in'}
	f[#f+1] = {':', 'asin', 'in'}
	f[#f+1] = {':', 'cos', 'in'}
	f[#f+1] = {':', 'acos', 'in'}
	f[#f+1] = {':', 'uit', {'^', 'byte', 'int'}}
	f[#f+1] = {'=', 'tau', tostring(2*math.pi)}
	f[#f+1] = {':', 'tau', 'getal'}
	f[#f+1] = {':', '-1', 'getal'}
	f[#f+1] = {':', 'coproduct', 'in'}
	]]

	return f
end
