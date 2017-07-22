require 'token'
local insert = table.insert

function name(token)
	return token:match('%w.*')
end

local precsource = {
	{'^', '_'},
	{'*', '/'},
	{'+', '-'},
	{'='},
	{'(',')'},
}

local precedence = {}
for i,ops in ipairs(precsource) do
	local v = #precsource - i + 1
	for j,op in ipairs(ops) do
		precedence[op] = v
	end
end

function parseInfix(src)
	local tokens = tokenize(src)
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

	local as = {}
	local hi = 0
	local br

	while peek(2) do
		local a
		if not br then
			a = pop()
		else
			a = br
			br = nil
		end
		if a == '(' then
			insert(as, {'['})
		elseif a == ')' then
			if as[#as][1] == '[' then
				error('lege haakjes')
			end

			-- vind openingshaakjes
			local open
			for i=#as,1,-1 do
				if as[i][1] == '[' then
					open = i
					break
				end
			end
			if not open then
				error('teveel sluitende haakjes')
			end

			-- collapse
			for i=#as,open+1,-1 do
				insert(as[#as-1], as[#as])
				as[#as] = nil
			end

			-- stop in stack
			as[#as-1] = copy(as[#as])
			br = copy(as[#as])
			as[#as] = nil
		else
			if peek() == ')' then
				insert(as[#as], a)
			else
				local op = pop()
				local pre = precedence[op]

				if not pre then
					error('ongeldige operator '..string.format('%q',op))
				end

				-- a + b * c
				if pre > hi then
					insert(as, {op, a})

				-- a * b + c
				else
					insert(as[#as], a)
					while #as > 1 and pre <= precedence[as[#as-1][1]] do
						insert(as[#as-1], as[#as])
						as[#as] = nil
						hi = precedence[as[#as][1]]
					end
					-- a + b - c
					local opb = as[#as][1]
					if op ~= opb then
						as[#as] = {op, as[#as]}
					end
				end
				hi = pre
			end
		end
	end

	-- laatste B
	local b = pop()
	insert(as[#as], b)

	-- collapse
	for i = #as-1,1,-1 do
		insert(as[i], as[i+1])
	end

	-- fix brackets

	return fix(as[1])
end

function fix(s)
	if exp(s) then
		if s[1] == '[' then
			s = s[2]
		end
		for i,sub in ipairs(s) do
			s[i] = fix(sub)
		end
	end
	return s
end

		-- fix brackets

-- zelf test
require 'sexp'

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
test('a^2 + b^2 + c^2 + d^2', '(+ (^ a 2) (^ b 2) (^ c 2) (^ d 2))')
test('a * b ^ c + d', '(+ (* a (^ b c)) d)')
test('a*b+c^d/e^f', '(+ (* a b) (/ (^ c d) (^ e f)))')
test('a+b^c/d', '(+ a (/ (^ b c) d))')
test('a*b+c^d/e^f - 8', '(- (+ (* a b) (/ (^ c d) (^ e f))) 8)')
test('a+b*c', '(+ a (* b c))')
test('(a+b)*c', '(* (+ a b) c)')
test('a=b+c', '(= a (+ b c))')
test('((a + b))', '(+ a b)')
test('(((a + b)))', '(+ a b)')
test('(a + b) * (c / (d - e))', '(* (+ a b) (/ c (- d e)))')
