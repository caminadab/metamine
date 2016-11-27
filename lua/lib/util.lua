-- util.lua
function ntoh(num)
    local mul = 0x1
    local res = 0
    for i=1,#num do
        res = res + mul * string.byte(num:sub(i,i))
        mul = mul * 0x100
    end
    
    return res
end

function hton(num, len)
	local n = {}
	for i=1,len do
		n[i] = num % 0x100
		num = math.floor(num / 0x100)
	end
	return string.char(table.unpack(n))
end

-- hex
function hex_encode(txt)
	local res = {}
	for i=1,#txt do
		table.insert(res, string.format("%02x", string.byte(txt:sub(i,i))))
	end
	return table.concat(res)
end

function hex_decode(hex)
	local res = {}
	for i=1,#hex-1,2 do
		local sub = hex:sub(i,i+1)
		local num = tonumber(sub, 16)
		table.insert(res, string.char(num))
	end
	return table.concat(res)
end

function string_replace(str, val, loc)
	local before = str:sub(1,loc-1)
	local after = str:sub(loc + #val,#str)
	return before..val..after
end
function linerange(src,from,to)
	-- find start
	local line = 1
	local start,stop
	local off = 1
	while true do
		if line == from then
			start = off
		elseif line == to+1 then
			stop = off
			break
		end
		off = src:find('\n',off+1)
		line = line + 1
	end
	print(start, stop)
	return src:sub(start, stop)
end

local function sascode2(tt,tabs,res)
	if type(tt) == 'table' then
		if not next(tt) then
			table.insert(res, '{}')
		else
			for k,v in pairs(tt) do
				table.insert(res, '\n')
				table.insert(res, tabs)
				table.insert(res, tostring(k))
				table.insert(res, ' ')
				
				sascode2(v,tabs..'  ',res)
			end
		end
	elseif type(tt) ~= 'boolean' then
		table.insert(res, tostring(tt))
	end
end

function sascode(tt)
	local res = {}
	sascode2(tt,'',res)
	return table.concat(res)
end