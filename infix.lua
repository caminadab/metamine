require 'token'
local insert = table.insert

function name(token)
	return token:match('%w.*')
end

local precsource = {
	{'^', '_'},
	{'*', '/'},
	{'+', '-'},
	--{'='},
}
local precmax = #precsource

local precedence = {}
for i,ops in ipairs(precsource) do
	local v = #precsource - i + 1
	for j,op in ipairs(ops) do
		precedence[op] = v
	end
end

function parseInfix(src)
	local tokens = tokenize(src)
	print(formatTokens(tokens))

	local i = 1
	local function pop()
		local token = tokens[i]
		if not token then
			error('eof')
		end
		i = i + 1
		return token
	end
	local function peek(n)
		n = n or 1
		return tokens[i + n-1]
	end

	-- 1 symbool blijft 1 symbool
	if not peek(2) then
		return tokens[1]
	end

	local hi = 0
	local as = {}
	while peek(2) do
		local a = pop()
		local op = pop()
		local pre = precedence[op]
		if not pre then
			error('ongeldige operator '..string.format('%q',p))
		end

		as[pre] = as[pre] or {}

		if pre < hi then
			-- afmaken
			insert(as[hi], a)
			as[pre] = {op, as[hi]}
			as[hi] = nil
		elseif pre > hi then
			-- nieuwe maken
			as[pre] = {op,a}
		else
			-- toevoegen
			local opb = as[pre][1]
			if op == opb then
				insert(as[pre], a)
			else
				insert(as[pre], a)
				as[pre] = {op, as[pre], }
			end
		end
		hi = pre
	end

	-- laatste B
	local b = pop()
	insert(as[hi], b)

	-- collapse
	local prev
	for i = precmax,1,-1 do
		if as[i] then
			if prev then
				insert(as[i], prev)
			end
			prev = as[i]
		end
	end
	
	return as[1]
end

-- zelf test
require 'sexp'
--local sexp = parseInfix 'a + b * 3'
local sexp = parseInfix 'a + b * 3^i'
print(unparse(sexp))

local function test(infix,prefix)
	local sexp = parseInfix(infix)
	local res = unparse(sexp)
	assert(res == prefix, 'expected '..prefix..', actual '..res)
end

-- zelfde level
test('a + b', '(+ a b)')
test('a + b + c', '(+ a b c)')
test('a + b - c', '(- (+ a b) c)')
test('a + b + c - d - e - f', '(- (+ a b c) d e f)')

-- moeilijker
test('a + b*3^i', '(+ a (* b (^ 3 i)))')
test('a + b^i', '(+ a (^ b i))')
test('a^2 + b^2 + c^2', '(+ (^ a 2) (^ b 2) (^ c 2))')
