require 'exp'
require 'func'
require 'set'

local postop = set("%","!",".","'",'²','³')
local binop  = set("+","·","/","^","∨","∧","×","..","→","∘","_","⇒",">","≥","=","≠","≈","≤","<",":=","+=","|=","|:=", "∪","∩",":","∈","‖")
local unop   = set("-","#","¬","Σ","|","⋀","⋁","√","|")

function utf8to32(utf8str)
	assert(type(utf8str) == "string")
	local res, seq, val = {}, 0, nil
	for i = 1, #utf8str do
	local c = string.byte(utf8str, i)
	if seq == 0 then
	 table.insert(res, val)
	 seq = c < 0x80 and 1 or c < 0xE0 and 2 or c < 0xF0 and 3 or
				 c < 0xF8 and 4 or --c < 0xFC and 5 or c < 0xFE and 6 or
			error("invalid UTF-8 character sequence")
	 val = bit32.band(c, 2^(8-seq) - 1)
	else
	 val = bit32.bor(bit32.lshift(val, 6), bit32.band(c, 0x3F))
	end
	seq = seq - 1
	end
	table.insert(res, val)
	table.insert(res, 0)
	return res
end

	--[[
| bits | U+first   | U+last     | bytes | Byte_1   | Byte_2   | Byte_3   | Byte_4   | Byte_5   | Byte_6   |
+------+-----------+------------+-------+----------+----------+----------+----------+----------+----------+
|   7  | U+0000    | U+007F     |   1   | 0xxxxxxx |          |          |          |          |          |
|  11  | U+0080    | U+07FF     |   2   | 110xxxxx | 10xxxxxx |          |          |          |          |
|  16  | U+0800    | U+FFFF     |   3   | 1110xxxx | 10xxxxxx | 10xxxxxx |          |          |          |
|  21  | U+10000   | U+1FFFFF   |   4   | 11110xxx | 10xxxxxx | 10xxxxxx | 10xxxxxx |          |          |
| *26  | U+200000  | U+3FFFFFF  |   5   | 111110xx | 10xxxxxx | 10xxxxxx | 10xxxxxx | 10xxxxxx |          |
| *31  | U+4000000 | U+7FFFFFFF |   6   | 1111110x | 10xxxxxx | 10xxxxxx | 10xxxxxx | 10xxxxxx | 10xxxxxx |
--]]
function codepoint_to_utf8(c)
    assert((55296 > c or c > 57343) and c < 1114112, "Bad Unicode code point: "..c..".")
    if     c < 128 then
        return                                                          string.char(c)
    elseif c < 2048 then
        return                                     string.char(192 + c/64, 128 + c%64)
    elseif c < 55296 or 57343 < c and c < 65536 then
        return                    string.char(224 + c/4096, 128 + c/64%64, 128 + c%64)
    elseif c < 1114112 then
        return string.char(240 + c/262144, 128 + c/4096%64, 128 + c/64%64, 128 + c%64)
    end
end

local function combineerR(exp, t, kind)
	if (combal[exp] or 0) >= 3 then
		t[#t+1] = '...'
		return
	end
	combal[exp] = (combal[exp] or 0) + 1
	if not exp then
		t[#t+1] = '?'
	elseif fn(exp) == '→' and atoom(arg0(exp)) == 'nat' then
		t[#t+1] =  'lijst '
		combineerR(arg1(exp), t, true)
	elseif isatoom(exp) and postop[exp.v] or binop[exp.v] or unop[exp.v] then
		t[#t+1] = '('
		t[#t+1] = exp.v
		t[#t+1] = ')'
	elseif isatoom(exp) then
		t[#t+1] = exp.v
	elseif obj(exp) == '"' then
		local const = true
		for i,sub in ipairs(exp) do
			if not tonumber(atoom(sub)) then
				const = false
			end
		end
		if const then
			local r = {}
			for i,sub in ipairs(exp) do
				r[#r+1] = codepoint_to_utf8(tonumber(sub.v))
			end

			local tekst = table.concat(r) --string.char(table.unpack(r))

			t[#t+1] = string.format('%q', tekst):gsub('\n', 'n')

		else

			t[#t+1] = "unicode ["
			for i,v in ipairs(exp) do
				if i ~= 1 then
					t[#t+1] = ', '
				end
				combineerR(v, t, true)
			end
			t[#t+1] = "]"
		end

	elseif isobj(exp) then
		local di = obj(exp)
		if di == ',' then
			di = '()'
		end
		t[#t+1] = di:sub(1,1)
		for i,v in ipairs(exp) do
			if i ~= 1 then
				t[#t+1] = ', '
			end
			if i > 20 then
				t[#t+1] = '...'
				break
			end
			combineerR(v, t, true)
		end
		t[#t+1] = di:sub(2,2)

	-- explijst
	elseif fn(exp) == '⋀' and isobj(exp.a) then
		for i,sub in ipairs(exp.a) do
			combineerR(sub, t, false)
			t[#t+1] = '\n'
		end

	elseif isfn(exp) then
		if not exp.a then return '?' end
		local op = fn(exp)
		if op == '_' or op == '_l' or op == '_f' and isobj(exp.a) then

			if isfn(exp.a[1]) then
				t[#t+1] = '('
			end
			combineerR(exp.a[1], t, true)
			if isfn(exp.a[1]) then
				t[#t+1] = ')'
			end

			t[#t+1] = ' '
			if not isobj(exp.a[2]) then
				t[#t+1] = '('
			end
			combineerR(exp.a[2], t, false)
			if not isobj(exp.a[2]) then
				t[#t+1] = ')'
			end

		-- a + b 
		elseif binop[op] and isobj(exp.a) then
			if kind then t[#t+1] = '(' end
			combineerR(exp.a[1], t, true)
			t[#t+1] = ' '
			t[#t+1] = op
			t[#t+1] = ' '
			combineerR(exp.a[2], t, true)
			if kind then t[#t+1] = ')' end

		elseif unop[op] then
			t[#t+1] = op
			t[#t+1] = ' '
			combineerR(exp.a, t, true)
		elseif postop[op] then
			combineerR(exp.a, t, true)
			t[#t+1] = op
		else
			t[#t+1] = '('
			t[#t+1] = op
			t[#t+1] = ')'
			if exp.a and not isobj(exp.a) then
				t[#t+1] = '('
			end
			combineerR(exp.a, t, false)
			if not isobj(exp.a) then
				t[#t+1] = ')'
			end
		end

	else
		--error('ongeldige exp '..e2s(exp))
		t[#t+1] = '?'
	end
end

function combineer(exp)
	local t = {}
	combal = {}
	combineerR(exp, t, false)
	return table.concat(t)
end

-- combineer maar 1 level
function combineersimpel(exp)
	if isatoom(exp) then
		return combineer(exp)
	else
		local nep = {}
		nep.f = exp.f
		nep.o = exp.o
		for k,sub in subs(exp) do
			nep[k] = (isatoom(sub) and sub) or (sub.ref and X(sub.ref)) or X'...'
		end
		nep.exp = nil
		return combineer(nep)
	end
end

C = combineer
