--require 'token'
require 'lisp'
require 'func'

local insert = table.insert

function name(token)
	return token and isatoom(token) and string.match(token,'%a[%w%-]*$')
end

local openBrackets = {
	['('] = true, ['['] = true, ['{'] = true,
}

local closeBrackets = {
	[')'] = true, [']'] = true, ['}'] = true,
}

local binops = {
	{'.'},
	{',', 'X'},
	{'^', '_'},
	{'|', '&'},
	{'*', '/'},
	{'+', '-'},
	{'%'},
	{'>', '<', '=<', '>='},

	{'||'},
	{'..', 'to'},
	{'>>', '<<', ':'},
	{'='},
	{'=?'},
	{'and', 'or', 'xor', 'nand', 'nor', 'xnor', 'xnand'},
	{'<=>', '=>', '<='},
	{'\n'},
}

local binopNames = {
	['.'] = 'index',
	[','] = 'comma',
	['X'] = 'cart-product',
	['^'] = 'pow',
	['_'] = 'log',
	['|'] = 'in-or',
	['&'] = 'in-and',
	['*'] = 'mul',
	['/'] = 'div',
	['+'] = 'add',
	['-'] = 'sub',
	['%'] = 'mod',
	['>'] = 'gt',
	['<'] = 'lt',
	['=<' ] = 'lte',
	['>=' ] = 'gte',
	['||' ] = 'concat',
	['..' ] = 'int-range',
	['to' ] = 'num-range',
	['>>' ] = 'conv',
	['<<' ] = 'conv-from',
	[':'  ] = 'in',
	['='  ] = 'eq',
	['=?' ] = 'assert-eq',
	['and'] = 'and',
	['or' ] = 'or',
	['xor'] = 'xor',
	['nand'] = 'nand',
	['nor'] = 'nor',
	['xnor'] = 'xnor',
	['xnand'] = 'xnand',
	['<=>'] = 'deduce',
	['=>' ] = 'deduce-to',
	['<=' ] = 'deduce-from',
	['\n' ] = 'newline',
}

local unopNames = {
	['+'] = 'pos',
	['-'] = 'neg',
	['+-'] = 'pos',
	['_'] = 'log',
	['^'] = 'exp',
	['#'] = 'count',
	[':'] = 'member',
	['not'] = 'not',
}
local unopSymbols = {}
for symbol,name in pairs(unopNames) do
	unopSymbols[name] = symbol
end

local unops = {
	'+', '-', '+-', '_', '^', '#', ':', 'not',
}

local binop = {}
for i,ops in ipairs(binops) do
	local v = #binops - i + 1
	for j,op in ipairs(ops) do
		binop[op] = v
	end
end

local unop = {}
for op,name in pairs(unopNames) do
	unop[op] = true
	unop[name] = true
end

local function fix(a)
	if isatoom(a) then
		if unopSymbols[a.v] then
			return unopSymbols[a.v]
		else
			return a
		end
	else
		local b = {}
		for i,v in ipairs(a) do
			b[i] = fix(v)
		end
		return b
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
			line = line + 1
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
			-- "# A"
			elseif unop[stack[#stack]] then
				stack[#stack] = {stack[#stack], a}
			else
				stack[#stack] = {stack[#stack], a}
				--error('regel '..line..': onvouwbaar: '..unparseSexp(stack[#stack])..' en '..unparseSexp(a))
			end
		end
	end
	local function apre(i)
		-- sin[
		if name(stack[i]) then return 999 end
		if not stack[i] or isatoom(stack[i]) then
			return 0
		end
		return binop[stack[i][1]]
	end
	-- gelegenheid voor unop?
	local function aunop()
		if #stack == 0 then return true end -- leeg, kan! denk "-a"
		if unop[stack[#stack]] then return true end -- "# ..."
		if exp(stack[#stack]) and not unopSymbols[stack[#stack][1]] and # stack[#stack] < 3 then return true end -- "a + ...", "# ..."
		if stack[#stack] == '[' then return true end -- "( # ... )"
		return false
	end
	-- verwerk tokens
	while peek() do
		local t = pop()

		if openBrackets[t] then
			apush('[')

		elseif closeBrackets[t] then
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

		-- +-
		elseif unop[t] and aunop() then
			stack[#stack+1] = unopNames[t]

		elseif binop[t] then
			-- operator
			local pre = binop[t]
			if not pre then
				error('regel '..line..': '..'onbekende operator '..t)
			end
			if not apre(#stack-1) then
				error('regel '..line)--..': '..'onbekende operator '..stack[#stack-1])
			end
			while pre <= apre(#stack-1) do
				afold(1)
			end

			if not stack[#stack] then
				-- lege expressie
				error('regel '..line..': '..'lege expressie, gesloten door '..t)
			end

			stack[#stack] = {t, stack[#stack]}

		-- # a
		elseif unop[stack[#stack]] then
			stack[#stack] = {stack[#stack], t}

		elseif name(stack[#stack]) then
			stack[#stack] = {stack[#stack], t}

		else
			apush(t)

		end
		--print(unparseSexp(stack))
	end

	afold(#stack-1)

	if not stack[1] then
		error('niets gevonden')
	end
	return fix(stack[1])
end

parseInfix = curry(infix, tokenize)

local insert = table.insert

local function unparseInfix_work(sexp, tt)
	if isatoom(sexp) then
		insert(tt, sexp.v)
	else
		local op = sexp.fn.v

		-- lijst/set
		if op == '[]' or op == '{}' then
			insert(tt, op:sub(1,1))
			for i=1,#sexp do
				unparseInfix_work(sexp[i], tt)
				if i ~= #sexp then
					insert(tt, ', ')
				end
			end
			insert(tt, op:sub(2,2))

		-- navoegsel
		elseif op == '%' or op == "'" then
			unparseInfix_work(sexp[1], tt)
			insert(tt, op)

		-- unop
		elseif #sexp == 1 then
			insert(tt, op)
			if isatoom(sexp[1]) then
				insert(tt, ' ')
				insert(tt, sexp[1].v)
			else
				insert(tt, ' (')
				unparseInfix_work(sexp[1], tt)
				insert(tt, ')')
			end

		-- binop
		else
			for i=1,#sexp do
				local v = sexp[i]
				local br = isfn(v) and binop[v[1]] and binop[op] and binop[v[1]] <= binop[op]

				if br then insert(tt, '(') end

				unparseInfix_work(sexp[i], tt)

				if br then insert(tt, ')') end

				if i ~= #sexp then
					if op ~= ',' and op ~= '^' then
						insert(tt, ' ')
					end
					insert(tt, op)
					if op ~= ',' and op ~= '^' then
						insert(tt, ' ')
					end
				end
			end

		end
	end
	-- plet
	for i,v in ipairs(tt) do
		if isexp(v) then
			tt[i] = unlisp(tt[i])
		end
	end
	return tt
end

function combineer(sexp)
	if not sexp then
		return '<niets>'
		--error('ongeldige s-exp')
	end

	local tt = unparseInfix_work(sexp, {})
	return table.concat(tt)
end

-- zelf test
local function test(infix,prefix)
	-- fase A
	local sexp = parseInfix(infix)
	local res = unparseSexpCompact(sexp)

	assert(res == prefix, 'parseInfix: expected '..prefix..', actual '..res)

	-- fase B
	local infix2 = unparseInfix(sexp)
	local sexp2 = parseInfix(infix2)
	local res2 = unparseSexpCompact(sexp2)
	assert(res == res2, 'unparseInfix: verwacht "'..infix..'", eigenlijk "'..infix2..'", s-exp: '..res2)
end

if _G.test then
	do return end
	test('sin(a) * b', '(* (sin a) b)')

	-- functies!
	test('sin a', '(sin a)')
	test('sin[tau]', '(sin tau)')
	test('sin[3*4]', '(sin (* 3 4))')
	test('sin(a) * b', '(* (sin a) b)')
	test('sin(a,b)', '(sin (, a b))')
	test('sin a * 3', '(* (sin a) 3)')

	-- unaire opn
	test('-a', '(- a)')
	test('a * -b', '(* a (- b))')
	test('a + - -b', '(+ a (- (- b)))')
	test('a * (-b)', '(* a (- b))')
	test('((-b))', '(- b)')
	test('-a - b', '(- (- a) b)')
	test('a - -b', '(- a (- b))')
	test('-a - b', '(- (- a) b)')
	test('- #a', '(- (# a))')

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
end
