require 'sexpr'
require 'util'

local rules = parse(file('optimize.lsp'))

function match(sexpr, src, map)
	map = map or {}
	if #sexpr ~= #src then return false end

	-- match it
	for i=1,#src do 
		if type(src[i])=='string' and string.lower(src[i])~=src[i] then
			if map[src[i]] and map[src[i]]~=sexpr[i] then
				return false -- mismatch
			end
			map[src[i]] = sexpr[i]
		elseif type(src[i])=='table' and type(sexpr[i])=='table' then
			local b = match(sexpr[i], src[i], map)
			if not b then
				return false
			end
		elseif src[i]~=sexpr[i] then
			return false
		end
	end

	-- substitute
	return map
end

function substitute(sexpr, map)
	if type(sexpr)=='string' and string.lower(sexpr)~=sexpr then
		if map[sexpr] == nil then
			error('optimization substitution failed: symbol '..sexpr..' not found')
		end
		return map[sexpr]
	elseif type(sexpr)=='table' then
		local res = {}
		for i=1,#sexpr do
			res[i] = substitute(sexpr[i], map)
		end
		return res
	else
		return sexpr
	end
end

function optimize(s)
	if type(s)=='string' then return s end

	-- children
	for i=2,#s do
		s[i] = eval(s[i])
	end

	-- specific rules!
	for rule in args(rules) do
		local map = match(s, rule[2])
		if map then
			s = substitute(rule[3], map)
			--print('USING RULE')
			--print(unparse_small(rule))
			--print('WE GOT')
			--print(unparse_small(s))
			if type(s)=='table' then
				s = eval(s)
			end
		end
	end

	return s
end
