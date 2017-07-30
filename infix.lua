require 'token'
require 'sexp'
require 'func'

local insert = table.insert

function name(token)
	return token:match('%w.*')
end

local precsource = {
	{'.'},
	{',', 'X'},
	{'^', '_'},
	{'*', '/'},
	{'+', '-'},
	{'%'},
	{'>', '<', '=<', '>='},

	{'||'},
	{'|', '&'},
	{'..', 'to'},
	{'>>', '<<', ':'},
	{'='},
	{'=?'},
	{'and', 'or', 'xor', 'nand', 'nor', 'xnor', 'xnand'},
	{'<=>', '=>', '<='},
	{'\n'},
}

local precedence = {}
for i,ops in ipairs(precsource) do
	local v = #precsource - i + 1
	for j,op in ipairs(ops) do
		precedence[op] = v
	end
end

function infix(tokens)
	-- remove comments
	for i,token in ipairs(tokens) do
		if token:sub(1,1)==';' then
			table.remove(tokens,i)
		end
	end

	-- line hack
	-- dubbel
	for i=#tokens,2,-1 do
		if tokens[i]=='\n' and tokens[i-1]=='\n' then
			table.remove(tokens, i)
		end
	end

	-- begin
	while tokens[1]=='\n' do
		table.remove(tokens, 1)
	end
	
	-- einde
	while tokens[#tokens]=='\n' do
		table.remove(tokens, #tokens)
	end

	-- token manage
	local line = 1
	local i = 1
	local function pop()
		local token = tokens[i]
		if not token then
			error('eof')
		end

		-- keep track
		if token == '\n' then
			line = line + i
		end

		i = i + 1
		return token
	end
	local function peek(n)
		n = n or 1
		return tokens[i + n-1]
	end
	
	-- stack manage
	local stack = {}
	local function apush(a)
		insert(stack, a)
	end
	local function apop()
		local a = stack[#stack]
		stack[#stack] = nil
		return a
	end
	local function afold(n)
		for i=1,n do
			local a = apop()
			if stack[#stack] == '[' then
				stack[#stack] = a
			elseif exp(stack[#stack]) then
				insert(stack[#stack], a)
			else
				--stack[#stack] = {stack[#stack], a}
				error('regel '..line..': onvouwbaar: '..unparseSexp(stack[#stack])..' en '..unparseSexp(a))
			end
		end
	end
	local function apre(i)
		if not stack[i] or atom(stack[i]) then
			return 0
		end
		return precedence[stack[i][1]]
	end
	-- verwerk tokens
	while peek() do
		local t = pop()

		if t == '(' then
			apush('[')

		elseif t == ')' then
			local begin
			for i=#stack,1,-1 do
				if stack[i] == '[' then
					begin = i
					break
				end
			end
			if not begin then
				error('regel '..line..': '..'teveel sluitende haakjes')
			end
			afold(#stack-begin)

		elseif precedence[t] then
			-- operator
			local pre = precedence[t]
			if not pre then
				error('regel '..line..': '..'onbekende operator '..t)
			end
			while pre <= apre(#stack-1) do
				afold(1)
			end

			if not stack[#stack] then
				error('regel '..line..': '..'niet genoeg operatoren op de stapel '..t)
			end

			stack[#stack] = {t, stack[#stack]}

		else
			apush(t)

		end
	end

	afold(#stack-1)

	if not stack[1] then
		error('niets gevonden')
	end
	return stack[1]
end

parseInfix = curry(infix, tokenize)


local insert = table.insert

local function unparseInfix_work(sexp, tt)
	if atom(sexp) then
		insert(tt, sexp)
	else
		local op = sexp[1]
		for i=2,#sexp do
			local v = sexp[i]
			local br = exp(v) and precedence[v[1]] < precedence[op]

			if br then insert(tt, '(') end

			unparseInfix_work(sexp[i], tt)

			if br then insert(tt, ')') end

			if i ~= #sexp then
				if op ~= ',' then
					insert(tt, ' ')
				end
				insert(tt, op)
				if op ~= ',' then
					insert(tt, ' ')
				end
			end
		end
	end
	return tt
end

function unparseInfix(sexp)
	if not sexp then
		error('ongeldige s-exp')
	end

	local tt = unparseInfix_work(sexp, {})
	return table.concat(tt)
end

-- zelf test
require 'sexp'

local function test(infix,prefix)
	-- fase A
	local sexp = parseInfix(infix)
	local res = unparseSexpCompact(sexp)

	assert(res == prefix, 'parseInfix: expected '..prefix..', actual '..res)

	-- fase B
	local infix2 = unparseInfix(sexp)
	local sexp2 = parseInfix(infix2)
	local res2 = unparseSexpCompact(sexp2)
	assert(res == res2, 'unparseInfix: expected '..infix..', actual '..infix2..', '..res2)
end

-- zelfde level
test('a + b', '(+ a b)')
test('a + b + c', '(+ (+ a b) c)')
test('a + b - c', '(- (+ a b) c)')
test('a + b + c - d - e - f', '(- (- (- (+ (+ a b) c) d) e) f)')

-- moeilijker
test('a + b*3^i', '(+ a (* b (^ 3 i)))')
test('a + b^i', '(+ a (^ b i))')
test('a^2 + b^2 + c^2 + d^2', '(+ (+ (+ (^ a 2) (^ b 2)) (^ c 2)) (^ d 2))')
test('a * b ^ c + d', '(+ (* a (^ b c)) d)')
test('a*b+c^d/e^f', '(+ (* a b) (/ (^ c d) (^ e f)))')
test('a+b^c/d', '(+ a (/ (^ b c) d))')
test('a*b+c^d/e^f - 8', '(- (+ (* a b) (/ (^ c d) (^ e f))) 8)')
test('a=b+c', '(= a (+ b c))')
test('((a + b))', '(+ a b)')
test('(((a + b)))', '(+ a b)')

test('a + b * c', '(+ a (* b c))')
test('a * b + c', '(+ (* a b) c)')
test('(a + b) * c', '(* (+ a b) c)')

test('a+b*c', '(+ a (* b c))')
test('(a+b)*c', '(* (+ a b) c)')
test('(a + b) * c', '(* (+ a b) c)')
test('(a + b) * c / (d - e)', '(/ (* (+ a b) c) (- d e))')
test('((((a))))', 'a')
test('a', 'a')

-- regels
test('a = 1\nb = 2', '(\n (= a 1) (= b 2))')
test('\na = 1\n\n\nb = 2\n\n', '(\n (= a 1) (= b 2))')
test('\na = 1\n\n\nb = 2\n\nc=3\n',
	'(\n (\n (= a 1) (= b 2)) (= c 3))')
