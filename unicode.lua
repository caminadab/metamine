function utf8pairs(str)
	local i = 1
	local index = 1

	return function()

		local value
		local a, b, c, d = string.byte (str, index, index+3)
		a, b, c, d = a or 0, b or 0, c or 0, d or 0

		if a <= 0x7f then
			value = a
			len = 1
		elseif 0xc0 <= a and a <= 0xdf and b >= 0x80 then
			value = (a - 0xc0) * 0x40 + b - 0x80
			len = 2
		elseif 0xe0 <= a and a <= 0xef and b >= 0x80 and c >= 0x80 then
			value = ((a - 0xe0) * 0x40 + b - 0x80) * 0x40 + c - 0x80
			len = 3
		elseif 0xf0 <= a and a <= 0xf7 and b >= 0x80 and c >= 0x80 and d >= 0x80 then
			value = (((a - 0xf0) * 0x40 + b - 0x80) * 0x40 + c - 0x80) * 0x40 + d - 0x80
			len = 4
		else
			value = -1
			len = 1
		end

		--print('i', i, str:sub(i,i+len-1))

		local previ = i
		local previndex = index
		i = i + 1
		index = index + len
		
		if previ > #str then
			previ = nil
			value = nil
		end

		return previ, value
	end
end
