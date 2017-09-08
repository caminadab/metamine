-- token types
local comment = 'comment'
local insert = table.insert

local function stream(src)
	local off = 1
	local get = function (n)
		local n = n or 0
		local off = off + n
		if off > #src then
			return nil
		end
		local ch = string.sub(src,off,off)
		return ch
	end
		
	local consume = function ()
		off = off + 1
	end

	local function peek()
		return string.sub(src, off+1, off+1)
	end

	return {
		get=get,
		consume=consume,
		peek=peek,
	}
end

local esc = {
	r = 10, -- cr
	n = 13, -- nl
	['\\'] = '\\',
}
local hex = {
	['0'] = 0, ['1'] = 1, ['2'] = 2, ['3'] = 3,
	['4'] = 4, ['5'] = 5, ['6'] = 6, ['7'] = 7,
	['8'] = 8, ['9'] = 9, ['A'] = 10, ['B'] = 11,
	['C'] = 12, ['D'] = 13, ['E'] = 14, ['F'] = 15,
}
local digit = {
	['0'] = 0, ['1'] = 1, ['2'] = 2, ['3'] = 3,
	['4'] = 4, ['5'] = 5, ['6'] = 6, ['7'] = 7,
	['8'] = 8, ['9'] = 9,
}

local base = {
		b = 2, q = 4, o = 8, h = 16,
		d = 10
}

-- nul = \00
local function getText(ss)
	local get,consume = ss.get,ss.consume
	local token = {'\''}
	consume()
	while get() do
		local ch
		if get() == '\\' then
			consume()
			if hex[get()] then
				local hi = hex[get()]
				consume()
				if hex[get()] then
					local lo = hex[get()]
					consume()
					ch = string.char(hi*16+lo)
				else
					error('geen tweede hex char')
				end
			elseif get() and esc[get()] then
				ch = esc[get()]
				consume()
			else
				error('onherkenbare esc')
			end
		elseif get() == '\'' then
			table.insert(token, get())
			consume()
			break
		else
			ch = get()
			consume()
		end
		table.insert(token, ch)
	end
	return table.concat(token)
end

local function getComment(ss)
	local get,consume = ss.get,ss.consume
	local text = {';'}
	consume()
	while get() and get()~='\n' do
		table.insert(text, get())
		consume()
	end
	return table.concat(text)
end

local function getNumber(ss)
	local get,consume = ss.get,ss.consume
	local text = {}
	local high = 0

	-- optional - or +
	if get()=='-' or get()=='+' then
		table.insert(text,get())
		consume()
	end

	while get() and hex[get()] do
		high = math.max(high, hex[get()])
		table.insert(text, get())
		consume()
	end

	-- decimaal deel
	if get() == '.' and hex[get(1)] then
		table.insert(text, get())
		consume()
		while get() and hex[get()] do
			high = math.max(high, hex[get()])
			table.insert(text, get())
			consume()
		end
	end

	-- base postfix
	local postfix = get()
	if base[postfix] then
		table.insert(text, get())
		consume()
	end
	local base = base[postfix] or 10

	if high >= base then
		error('nummer niet uitdrukbaar in base '..base)
	end

	return table.concat(text)
end

-- haakjes
local bracket = {
	['('] = true, [')'] = true,
	['['] = true, [']'] = true,
	['{'] = true, ['}'] = true,
}

-- operatoren
-- dubbel: || <= >= :: .. 
local double = {
	['||'] = true, ['<='] = true,
	['>='] = true, ['::'] = true,
	['=>'] = true, ['!='] = true,
	['>>'] = true, ['<<'] = true,
	['..'] = true, ['+-'] = true
}
local operator = {}
local optext = '\\+-*/.,^|&=?!><:#%X_@'
for i=1,#optext do
	operator[string.sub(optext,i,i)] = true
end

local function getOperator(ss)
	local get,consume = ss.get,ss.consume
	local text = {}

	local first = get()
	insert(text, first)
	consume()

	-- double?
	if double[first..get()] then
		insert(text, get())
		consume()
	end

	return table.concat(text)
end

local function getVariable(ss)
	local get,consume = ss.get,ss.consume
	local text = {}
	while get() and get():match('[%w%d-]') do
		if get() == '-' and not get(1):match('[%w%d]') then break end
		table.insert(text, get())
		consume()
	end
	return table.concat(text)
end

local white = {
	[' '] = true, ['\t'] = true, ['\r'] = true
}

local function skipWhite(ss)
	local get,consume = ss.get,ss.consume
	while white[get()] do
		consume()
	end
end

function tokenize(src)
	local tokens = {}
	local ss = stream(src)
	local get,consume,peek = ss.get,ss.consume,ss.peek

	while skipWhite(ss) or get() do
		local token
		
		-- comment
		if get()==';' then
			token = getComment(ss)

		-- newline
		elseif get()=='\n' then
			token = '\n'
			consume()

		-- tekst
		elseif get()=='\'' then
			token = getText(ss)

		-- getal (3, -2)
		elseif digit[get()]
				or (get()=='-' and digit[peek()]) then
			token = getNumber(ss)

		-- haakjes
		elseif bracket[get()] then
			local ch = get()
			consume()
			token = ch

		-- operatoren
		elseif operator[get()] then
			token = getOperator(ss)

		-- variabele
		elseif get():match('%w') then
			token = getVariable(ss)

		-- error
		else
			error('onherkenbaar karakter '..get())

		end

		table.insert(tokens,token)
	end

	return tokens
end


require 'sexp'
local function test(src,num)
	local tokens = tokenize(src)
	local exp = table.concat(tokens, ' ')
	assert(src==exp, exp)
	if num then
		assert(#tokens == num)
	end
end

test[[a + 3]]
test[[+- a]]
test[[0 .. 1]]
test[['hoi']]
test[['a' 'b']]
test([['a' || 'b']], 3)
test[[1 = -2 ;hoi]]
test[[max-alts = 4]]
test[[]]
test[[3 +- -3]]
test[[3 >> int]]
assert(table.concat(tokenize[[ i2[0..(#i2-#i1)] ]], ' ') == 
"i2 [ 0 .. ( # i2 - # i1 ) ]")
assert(table.concat(tokenize[[ 0..1 ]], ' ') == '0 .. 1')

function formatTokens(tokens)
	local res = {}
	for i,token in ipairs(tokens) do
		if i%2==0 then
			table.insert(res, '\x1B[34m')
		else
			table.insert(res, '\x1B[36m')
		end
		table.insert(res, token)
		table.insert(res, ' ')
	end
	table.insert(res, '\x1B[37m')
	return table.concat(res)
end

--print(formatTokens(tokenize('(c..a) + 3 * b ;hoi')))
