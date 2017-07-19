-- token types
local comment = 'comment'
-- token: {line=1,ch=1,type=X,text=}

local function stream(src)
	local off = 1
	local get = function ()
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
	-- base postfix
	if base[get()] then
		if high > base[get()] then
			error('nummer niet uitdrukbaar in base '..base[get()])
		end
		table.insert(text, get())
		consume()
	end
	return table.concat(text)
end

-- opeatoren
local operator = {}
local optext = '\\+-*/.,^|&=?!><():#%x'
for i=1,#optext do
	operator[string.sub(optext,i,i)] = true
end

local function getOperator(ss)
	local get,consume = ss.get,ss.consume
	local text = {}
	while get() and operator[get()] do
		table.insert(text, get())
		consume()
	end
	return table.concat(text)
end

local function getVariable(ss)
	local get,consume = ss.get,ss.consume
	local text = {}
	while get() and get():match('[%w%d]') do
		table.insert(text, get())
		consume()
	end
	return table.concat(text)
end

local white = {
	[' '] = true, ['\t'] = true, ['\n'] = true, ['\r'] = true
}

local function skipWhite(ss)
	local get,consume = ss.get,ss.consume
	while white[get()] do
		consume()
	end
end

local function tokenize(src)
	local tokens = {}
	local ss = stream(src)
	local get,consume,peek = ss.get,ss.consume,ss.peek

	while skipWhite(ss) or get() do
		local token
		
		-- comment
		if get()==';' then
			token = getComment(ss)

		-- tekst
		elseif get()=='\'' then
			token = getText(ss)

		-- getal (3, -2)
		elseif digit[get()]
				or (get()=='-' and digit[peek()]) then
			token = getNumber(ss)

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


function fromInfix(src)
	local tokens = tokenize(src)
end

function at(src)
	local exp = table.concat(tokenize(src), ' ')
	assert(src==exp, exp)
end

at[[a + 3]]
at[[+- a]]
at[['hoi']]
at[['a''b']]
at[['a' || 'b']]
at[[1 = -2 ;hoi]]
at[[]]
	
