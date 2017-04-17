function head(t) return t[1] end
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
		local ch = sexpr:sub(i,i)
		if ch=='' then
			ch = nil
		end
		return ch
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

local function unparse_work(sexpr, tabs, res)
	tabs = tabs or 0
	res = res or {}
	if type(sexpr) == 'string' then
		table.insert(res, sexpr)
	elseif type(sexpr) == 'table' then
		-- alleen lijnen als we complex zijn!
		local complex = false
		for i,sub in ipairs(sexpr) do
			if type(sub)=='table' then
				complex = true
			end
		end

		table.insert(res, '(')

			-- BEGIN --
			if #sexpr==3 then
			local s = {}
			for i,v in ipairs(sexpr) do
				s[i] = v
			end
			 sexpr = s
			sexpr[2],sexpr[1] = sexpr[1],sexpr[2]
			end
			-- EINDE --

		if complex then

			-- BEGIN
			if #sexpr==3 then
			table.insert(res, '\n')
			table.insert(res, string.rep('  ',tabs+1))
			end
			-- EINDE

			for i,sub in ipairs(sexpr) do
				if i > 1 then
					table.insert(res, string.rep('  ',tabs+1))
				end
				unparse_work(sub, tabs+1, res)
				table.insert(res, '\n')
			end
			table.insert(res, string.rep('  ',tabs))
		else
			for i,sub in ipairs(sexpr) do
				unparse_work(sub, tabs+1, res)
				if next(sexpr, i) then
					table.insert(res, ' ')
				end
			end
		end
		
		table.insert(res, ')')
	else
		--error('sexpr is of type '..type(sexpr))
		table.insert(res, tostring(sexpr))
	end
	return res
end

function unparse(sexpr)
	return table.concat(unparse_work(sexpr))
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
