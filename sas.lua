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
	local sas = fix(infix)
	return sas
end

function unparse(sexp)
	-- TODO work
	return unparseInfix(sexp)
end

local function test(sas, sexp)
	local exp = unparseSexpCompact(parse(sas))
	assert(exp == sexp, exp)
end

test('a = 1\nb = 2\n\nc = 3', '(and (and (= a 1) (= b 2)) (= c 3))')
