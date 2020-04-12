function utf8encode(unicode)
	if unicode <= 0x7F then return string.char(unicode) end

	if (unicode <= 0x7FF) then
		local Byte0 = 0xC0 + math.floor(unicode / 0x40);
		local Byte1 = 0x80 + (unicode % 0x40);
		return string.char(Byte0, Byte1);
	end;

	if (unicode <= 0xFFFF) then
		local Byte0 = 0xE0 +  math.floor(unicode / 0x1000);
		local Byte1 = 0x80 + (math.floor(unicode / 0x40) % 0x40);
		local Byte2 = 0x80 + (unicode % 0x40);
		return string.char(Byte0, Byte1, Byte2);
	end;

	if (unicode <= 0x10FFFF) then
		local code = unicode
		local Byte3= 0x80 + (code % 0x40);
		code       = math.floor(code / 0x40)
		local Byte2= 0x80 + (code % 0x40);
		code       = math.floor(code / 0x40)
		local Byte1= 0x80 + (code % 0x40);
		code       = math.floor(code / 0x40)
		local Byte0= 0xF0 + code;

		return string.char(Byte0, Byte1, Byte2, Byte3);
	end;

	error 'unicode cannot be greater than U+10FFFF'
end

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
