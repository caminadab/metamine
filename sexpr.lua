function head(t)
	if type(t)~='table' then
		return nil
	end
	return t[1]
end

function atom(t)
	return type(t)=='string'
end

function exp(t)
	return type(t)=='table'
end

function args(s)
	local i = 1
	return function ()
		i = i + 1
		return s[i]
	end
end

function tail(tt)
	local res = {}
	for i=2,#tt do
		table.insert(res, tt[i])
	end
	return res
end

function parse(sexpr)
	local stack = {}
	local i = 1
	local line = 1
	local ch = 1
	
	function get()
		local char
		repeat
			char = sexpr:sub(i,i)
			if char == '' then
				char = nil
			end
			if char == ';' then
				i = sexpr:find('\n', i)
				line = line + 1
				ch = 1
			end
		until char ~= ';'
		return char
	end

	function consume()
		if sexpr[i] == '\n' then
			line = line + 1
			ch = 1
		else
			ch = ch + 1
		end
		i = i + 1
		return i > #sexpr
	end
	
	local blank = {[' ']=true, ['\r']=true, ['\n']=true, ['\t']=true}
	
	while i < #sexpr do
		-- skip space
		while blank[get()] do
			consume()
		end
		
		-- bracket?
		if get() == '(' then
			table.insert(stack, {})
			consume()
		
		-- close?
		elseif get() == ')' then
			if #stack == 1 then
				return stack[1]
				--error(line..':'..ch..'\tclosing too much')
			end
			table.insert(stack[#stack-1], stack[#stack])
			table.remove(stack, #stack)
			consume()

		-- error?
		elseif not get() then
			break
		
		-- list?
		else
			local id = {}
			while get() and not blank[get()] and get()~=')' and get()~='(' do
				table.insert(id, get())
				consume()
			end
			id = table.concat(id)
			if #stack == 0 then
				table.insert(stack, id)
			elseif type(stack[#stack]) ~= 'table' then
				error(line..':'..ch..'\ttoo much tokens')
			else
				table.insert(stack[#stack], id)
			end
		end
	end
	
	if #stack > 1 then
		error('missing closing parentheses')
	end
	
	return stack[1]
end

local function unparse_atom(atom)
	atom = string.format('%q', atom)
	atom = string.gsub(atom, '\n', '\\n')
	atom = atom:sub(2,-2)
	return atom
end

local function unparse_len(sexpr)
	local len
	if atom(sexpr) then
		len = #unparse_atom(sexpr)
	else
		len = 2 + #sexpr-1 -- (A B C)
		for i,sub in ipairs(sexpr) do
			len = len + unparse_len(sub)
		end
	end
	return len
end

local function unparse_work(sexpr, maxlen, tabs, res)
	tabs = tabs or 0
	res = res or {}
	if atom(sexpr) then
		len = #sexpr
		table.insert(res, unparse_atom(sexpr))
	else
		local split = unparse_len(sexpr) > maxlen
		table.insert(res, '(')
		for i,sub in ipairs(sexpr) do
			if split then
				table.insert(res, '\n')
				table.insert(res, string.rep('  ', tabs+1))
			end
			unparse_work(sub, maxlen, tabs+1, res)
			if next(sexpr, i) then
				table.insert(res, ' ')
			end
		end
		if split then
			table.insert(res, '\n')
			table.insert(res, string.rep('  ', tabs))
		end
		table.insert(res, ')')
	end
	return res
end

function unparse(sexpr)
	return table.concat(unparse_work(sexpr, 40))
end

function unparse_small(sexpr, res)
	if not res then
		return table.concat(unparse_small(sexpr,{}))
	end
	if type(sexpr)=='string' then
		table.insert(res,sexpr)
	else
		table.insert(res, '(')
		for i,sub in ipairs(sexpr) do
			unparse_small(sub, res)
			if next(sexpr, i) then
				table.insert(res, ' ')
			end
		end
		table.insert(res, ')')
	end
	return res
end
