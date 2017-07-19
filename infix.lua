-- token types
local comment = 'comment'
-- token: {line=1,ch=1,type=X,text=}

local function stream(src)
	local off = 1
	local get = function ()
		if off > #src then
			return nil
		end
		off = off + 1
		return string.sub(src, off, off)
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
	local get = ss.get
	local token = {}
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
			table.insert(token, ch)
		end
		table.insert(token, ch)
	end
	return table.concat(token)
end

local function getComment(ss)
	local get = ss.get
	local text = {}
	while get() and get()~='\n' do
		table.insert(text, get())
		consume()
	end
	return table.concat(text)
end

local function getNumber(ss)
	local get = ss.get
	local text = {}
	local high = 0
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
	local get = ss.get
	local text = {}
	while get() and operator[get()] do
		table.insert(text, get())
		consume()
	end
	return table.concat(text)
end

local function getVariable(ss)
	local get = ss.get
	local text = {}
	while get():match('[%w%d]') do
		table.insert(text, get())
		consume()
	end
	return table.concat(text)
end

local function tokenize(src)
	local tokens = {}
	local ss = stream(src)
	local get,consume,peek = ss.get,ss.consume,ss.peek

	while get() do
		local token
		
		-- comment
		if get()==';' then
			token = getComment()

		-- tekst
		elseif get()=='\'' then
			token = getText()

		-- getal (3, -2)
		elseif digit[get()]
				or (get()=='-' and digit[peek()]) then
			token = getNumber()

		-- operatoren
		elseif op[get()] then
			token = getOperator()

		-- variabele
		elseif get():match('%w') then
			token = getVariable()

		end
	end

	return tokens
end


function fromInfix(src)
	local tokens = tokenize(src)
end

local t = tokenize
assert(table.concat(t'2 + 3', ' ') == '2 + 3')
	
