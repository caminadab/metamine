require 'util'

function isatoom(exp) return exp and exp.v ~= nil end
function isfn(exp) return exp and exp.f ~= nil end
function isobj(exp) return exp and exp.o ~= nil end

local insert = table.insert
local concat = table.concat

function unparse_atom(atom)
  --atom = string.format('%q', atom)
  --atom = string.gsub(atom, '\n', '\\n')
  --atom = atom:sub(2,-2)
  return atom.v
end

nergens = {x1=-1,y1=-1,x2=-1,y2=-1}

local objs = set(',', '{}', '[]', '"')

function X(f, ...)
	local args = {...}
	
	-- fix
	if type(f) == 'string' then
		f = {v = f, loc = nergens}
	end
	for i, arg in ipairs(args) do
		if type(arg) == 'string' then
			args[i] = {v = arg, loc = nergens}
		end
	end

	if #args == 0 then
		if false and atoom(f) == ',' then
			return { o = f }
		else
			return f
		end
	elseif objs[f.v] then
		-- herbruik args
		args.o = f
		args.loc = nergens
		return args
	elseif #args > 1 then
		-- verbruik args
		args.o = X','
		args.loc = nergens
		return { f = f, a = args, loc = nergens }
	else
		assert(#args == 1)
		return { f = f, a = args[1], loc = nergens }
	end
end

function X1(fn,...)
	if type(fn) == 'string' then
		fn = {v=fn, loc=nergens}
	elseif type(fn) ~= 'table' then
		fn = {v=tostring(fn), loc=nergens}
	end

	local t = {...}
	local r
	if #t == 0 then
		return fn
	elseif fn.v == ',' then
		r = {f=fn,...}
	elseif #t == 1 then
		r = {loc=nergens,f=fn,a=t[1]}
	else
		r = {loc=nergens,f=fn,a={}}
		for i,s in ipairs(t) do
			r.f = X','
			if type(s) == 'table' then
				r.a[i] = s
			else
				r.a[i] = {v=tostring(s), loc = nergens}
			end
		end
	end
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
	for i,v in subs(exp) do
		len = len + unparse_len(v)
	end
	len = len + #exp - 1 + 2
	exp.len = len
	return len
end

function unparse_work(exp, maxlen, tabs, res, klaar)
	klaar = klaar or {}
  tabs = tabs or 0
  res = res or {}
	if klaar[exp] then
		if isatoom(exp) then
			insert(res, '~'..atoom(exp))
		else
			insert(res, '~')
		end
		return
	end
	klaar[exp] = true
  if isatoom(exp) then
    insert(res,atoom(exp))
	elseif fn(exp) == '""' then
		insert(res, '""(...)')
	elseif isfn(exp) or isobj(exp) then
		local len = unparse_len(exp) 
    local split = len > maxlen --len > maxlen and len < 1.4 * maxlen or len > 3 * maxlen and len < 5.5 * maxlen or len > 7 * maxlen
		--unparse_work(sexpr.f, maxlen, tabs+1, res)
		insert(res, fn(exp) or obj(exp))
		insert(res, color[(tabs%#color)+1])
		insert(res, '(')
		insert(res, color.white)

		-- arg is troubled?
		local t = exp
		if arg(t) and obj(arg(t)) == ',' then
			t = arg(t)
		end
			
    for i,sub in subs(t) do
      if split then
        insert(res, '\n')
        insert(res, string.rep('  ', tabs+1))
      end
      unparse_work(sub, maxlen, tabs+1, res, klaar)
      --if next(exp, i) and type(next(exp, i)) == 'number' then
			if tonumber(i) and t[i+1] then
        insert(res, ' ')
			end
      --end
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
		insert(res, color.white)
  else
		res[#res+1] = '?'
	end
  return res
end

function unlisp(sexpr, len)
  if not sexpr then return 'niets' end
  return concat(unparse_work(sexpr, 40))
end

function unlispcompact(sexpr, len)
  if not sexpr then return 'niets' end
  return concat(unparse_work(sexpr, 1e10))
end
