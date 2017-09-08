require 'infix'

local function fix(sexp)
	if atom(sexp) then
		if sexp=='\n' then
			return 'and'
		else
			return sexp
		end
	else
		for i,v in ipairs(sexp) do
			sexp[i] = fix(v)
		end
		return sexp
	end
end

function parse(src)
	local infix = parseInfix(src)
	if infix[1] == '\n' then infix[1] = '=>' end
	local sas = fix(infix)
	return sas
end

function unparse(sexp)
	if sexp == nil or atom(sexp) then
		return tostring(sexp)
	end
	local stats
	if sexp[1] == '=>' then
		stats = multi(sexp[2], 'and')
		table.insert(stats, sexp[3])
	elseif sexp[1] == 'and' then
		stats = multi(sexp, 'and')
	else
		return unparseInfix(sexp)
	end

	local res = {}
	for i=2,#stats do
		table.insert(res, unparseInfix(stats[i]))
		table.insert(res, '\n')
	end
	return table.concat(res)
end

local function test(sas, sexp)
	local exp = unparseSexpCompact(parse(sas))
	assert(exp == sexp, exp)
end

test('a = 1\nb = 2\n\nc = 3', '(=> (and (= a 1) (= b 2)) (= c 3))')
