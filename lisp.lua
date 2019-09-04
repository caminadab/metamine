require 'lex'
require 'util'

function isatoom(exp)
	if type(exp) ~= 'table' then see(exp); print(debug.traceback()) ; return true end
	assert(exp.v or (exp.f and (exp.a or exp[1])))
	return exp.v ~= nil
end

function isfn(exp)
	assert(exp)
	assert(exp.v or (exp.f and (exp.a or exp[1])))
	return exp.f ~= nil
end
isexp = isfn

local insert = table.insert
local concat = table.concat

function unparse_atom(atom)
  --atom = string.format('%q', atom)
  --atom = string.gsub(atom, '\n', '\\n')
  --atom = atom:sub(2,-2)
  return atom.v
end

local metaexp = {}

function uitgerold(exp)
	local i = 0
	local function r(exp, t)
		if isatoom(exp) then
			error('nee!')
			exp.i, i = i, i + 1
			t[#t+1] = "s"..exp.i.." :=  "..exp.v
		elseif exp.f.v == '->' and false then
			exp.i, i = i, i + 1
			t[#t+1] = "s"..exp.i.." :=  "..uitgerold(exp[2]) --exp2string(exp)
		else
			local x = {}
			if isatoom(exp.f) then
				x.f = exp.f
			else
				x.f = r(exp.f, t)
			end
			for i,v in ipairs(exp) do
				if isatoom(exp[i]) then
					x[i] = exp[i]
				else
					x[i] = r(exp[i], t)
				end
			end
			exp.i, i = i, i + 1
			t[#t+1] = "s"..exp.i.." :=  "..combineer(x)
		end
		return X("s"..exp.i)
	end
	local t = {}
	r(exp, t)
	return table.concat(t, '\n')..'\n'
end

			
			


-- X('a', 3, 10)

nergens = {x1=-1,y1=-1,x2=-1,y2=-1}

function X(fn,...)
	if type(fn) == 'string' then
		fn = {v=fn, loc=nergens}
	elseif type(fn) ~= 'table' then
		fn = {v=tostring(fn), loc=nergens}
	end

	local t = {...}
	local r
	if #t == 0 then
		r = fn
	else
		r = {loc=nergens,f=fn}
		for i,s in ipairs(t) do
			if type(s) == 'table' then
				r[i] = s
			else
				r[i] = {v=tostring(s), loc = nergens}
			end
		end
	end
	setmetatable(r, {__tostring=exp2string, __index=metaexp, __eq == function(a,b) return expmoes(a) == expmoes(b) end })
	return r
end

-- {fn='a'}
function unparse_len(exp)
	if not exp then return 1 end
	if exp.len then return exp.len end
	if exp == nil then return 0 end
	if type(exp) == 'string' then return #exp end
	if exp.v then return #exp.v end
	local len = 0

	if isatoom(exp) then return #(exp.v or '???') end

	len = len + unparse_len(exp.f)
	for i,v in ipairs(exp) do
		len = len + unparse_len(v)
	end
	len = len + #exp - 1 + 2
	exp.len = len
	return len
end

function unparse_len0(exp)
  local len
  if isatoom(exp) then
		if not exp.v then error(tostring(exp)) end
    len = #exp.v
  else
		if exp.f then len = unparse_len(exp.f) + 2 end
    len = 2 + #exp-1 -- (A B C)
    for i,sub in ipairs(exp) do
      len = len + unparse_len(sub)
    end
  end
  return len
end

function unparse_work(sexpr, maxlen, tabs, res)
  tabs = tabs or 0
  res = res or {}
  if isatoom(sexpr) then
    insert(res, tostring(sexpr.v))
		if sexpr.ref then
			insert(res, sexpr.ref.v)
		end
	elseif isfn(sexpr) and sexpr.f.v == '[]u' then
		insert(res, '[]u(...)')
	elseif isfn(sexpr) then
    local split = unparse_len(sexpr) > maxlen
		unparse_work(sexpr.f, maxlen, tabs+1, res)
		insert(res, color[(tabs%#color)+1])
		insert(res, '(')
		insert(res, color.white)

		-- arg is troubled?
		local t = sexpr
		if sexpr.a.f.v == ',' then
			t = sexpr.a.f
		else
			t = {sexpr.a}
		end
			
    for i,sub in ipairs(t) do
			if type(sub) == 'boolean' then
				sub = tostring(sub)
			end
      if split then
        insert(res, '\n')
        insert(res, string.rep('  ', tabs+1))
      end
      unparse_work(sub, maxlen, tabs+1, res)
      if next(sexpr, i) and type(next(sexpr, i)) == 'number' then
        insert(res, ' ')
      end
			if split then
				-- commentaar
				if isfn(sub) and sub[';'] then
					res[#res+1] = '\t; '
					res[#res+1] = sub[';']
				end
			end
    end
    if split then
      insert(res, '\n')
      insert(res, string.rep('  ', tabs))
    end
		insert(res, color[(tabs%#color)+1])
		insert(res, ')')
		if sexpr.ref then
			insert(res, sexpr.ref.v)
		end
		insert(res, color.white)
  else
		res[#res+1] = '?'
	end
  return res
end

function unlisp(sexpr, len)
  if not sexpr then return 'niets' end
	local t = unparse_work(sexpr, len or 20)
  return concat(unparse_work(sexpr, len or 20))
end

function lispNeq(self,other)
	if atom(self) ~= atom(other) then return false end
	if atom(self) and atom(other) then return self ~= other end
	if type(self) ~= 'table' or type(other) ~= 'table' then
		error('ongeldig type '..type(self)..', '..type(other))
	end
	if #self ~= #other then return true end
	for i,v in ipairs(self) do
		if lispNeq(self[i], other[i]) then
			return true
		end
	end
	return false
end

function parseSexp2(sexpr)
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
	
	while i <= #sexpr do
		-- skip space
		while blank[get()] do
			consume()
		end
		
		-- bracket?
		if get() == '(' then
			insert(stack, new())
			consume()
		
		-- close?
		elseif get() == ')' then
			if #stack == 1 then
				return stack[1]
				--error(line..':'..ch..'\tclosing too much')
			end
			insert(stack[#stack-1], stack[#stack])
			table.remove(stack, #stack)
			consume()

		-- error?
		elseif not get() then
			break
	
		-- list?
		else
			local id = {}
			-- string
			if get() == "'" then
				while get() and get() ~= "'" do
					if get() == '\\' then
						insert(id, '\\')
						consume()
						insert(id, get())
						consume()
					elseif get() == "'" then
						insert(id, get())
						consume()
						break
					else
						consume()
						insert(id, get())
					end
				end

			-- normal token
			else
				while get() and not blank[get()] and get()~=')' and get()~='(' do
					insert(id, get())
					consume()
				end
			end
			id = concat(id)
			if #stack == 0 then
				insert(stack, id)
			elseif type(stack[#stack]) ~= 'table' then
				error(line..':'..ch..'\tteveel delen')
			else
				insert(stack[#stack], id)
			end
		end
	end
	
	if #stack > 1 then
		error('te weinig sluitende haakjes')
	elseif #stack < 1 then
		error('niets meer over')
		return 
	end
	
	return stack[1]
end

require 'lex'
function lisp(t)
	local i = 1
	local noise = {[';']=true, [' ']=true,
	['\r']=true, ['\n']=true, ['\t']=true}
	local tokens = lex(t)
	local stack = {{}}
	if not tokens then
		error('parse-error')
	end

	function peek()
		-- skip comments
		while tokens[i] and
		noise[tokens[i]:sub(1,1)] do
			i = i + 1
		end
		return tokens[i]
	end

	function pop()
		local v = peek()
		i = i + 1
		return v
	end

	while true do
		local token = pop()

		if token == '(' then
			stack[#stack+1] = {}

		elseif token == ')' then
			if #stack == 1 then
				error('teveel sluitende haakjes')
			end
			insert(stack[#stack-1], stack[#stack])
			stack[#stack] = nil
		
		elseif not token then
			break
		
		else
			insert(stack[#stack], token)
		end
	end

	-- samenvoeg
	for i=#stack,2,-1 do
		insert(stack[i-1], stack[i])
	end

	if #stack[1] > 1 then
		--error('ruis na data')
	end
	return stack[1][1]
end

function maprec(waarde, map)
	if type(waarde) == 'table' then
		local r = {}
		for i,v in ipairs(waarde) do
			r[i] = maprec(v, map)
		end
		return r
	else
		return map(waarde)
	end
end

