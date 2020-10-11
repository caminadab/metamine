function template(fmt, dict)
	local function vervang(name)
		local waarde = assert(dict[name], 'ongedefinieerd: '..name)
		return waarde
	end
	return string.gsub(fmt, '%{(%w+)%}', vervang)
end

if test then
	local t = template('welkom, {name}', {name="baap"})
	assert(t == 'welkom, baap')
end
