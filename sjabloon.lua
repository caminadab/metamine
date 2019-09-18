function sjabloon(fmt, dict)
	local function vervang(naam)
		local waarde = assert(dict[naam], 'ongedefinieerd: '..naam)
		return waarde
	end
	return string.gsub(fmt, '%{(%w+)%}', vervang)
end

if test then
	local t = sjabloon('welkom, {naam}', {naam="baap"})
	assert(t == 'welkom, baap')
end
