local function unparse_atom(atom)
  atom = string.format('%q', atom)
  atom = string.gsub(atom, '\n', '\\n')
  atom = atom:sub(2,-2)
  return atom
end

local function unparse_len(sexp)
  local len
  if atom(sexp) then
    len = #unparse_atom(sexp)
  else
    len = 2 + #sexp-1 -- (A B C)
    for i,sub in ipairs(sexp) do
      len = len + unparse_len(sub)
    end
  end
  return len
end

function atom(sexp)
	return type(sexp) == 'string'
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

function unparseSexp(sexpr)
  if not sexpr then return 'none' end
  return table.concat(unparse_work(sexpr, 40))
end

