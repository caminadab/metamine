require 'lex'
require 'lisp'

--[[
exp: pureexp | userfunction
pureexp: 
	| list | set | if | function
	| symbol | number | text | data
	| '(' exp ')' | logicblock

logicblock: INDENT (indent exp newline)* DEDENT
linesep: eol indent
sep: linesep | (',' linesep?)
item: exp
collection: INDENT sep? (item sep)* item? DEDENT 
setcollection: INDENT sep? (item sep)* elseitem? DEDENT 
elseitem: 'else' '->' exp

list: '[' collection ']'
set: '{' setcollection '}'
arguments: '(' collection ')'
]]

local function peek(queue,n)
	local n = n or 0
	return queue.v[queue.i + n]
end
local function pop(queue)
	queue.i = queue.i + 1
	return queue.v[queue.i - 1]
end
local function copy(q)
	return {v=q.v, i=q.i, indent=q.indent}
end

--	| list | set | if | function
--	| symbol | number | text | data
--	| '(' exp ')' | logicblock

local function alt(t) return {f='alt',v=t} end
local function cat(t) return {f='cat',v=t} end
local function l(t)	return {f='lit',v=t} end -- literal
local function r(t)	return {f='ref',v=t} end -- reference
local function q(t) return {f='opt',v=t} end -- optional / maybe
local function mul(t) return {f='mul',v=t} end -- zero or more
local function plus(t) return {f='plus',v=t} end -- one or more
local function sub(t) return {f='sub', v=t} end -- a without b
local function fn(t) return {f='fn',v=t} end -- call function to check
local INDENT = {f='indent'}
local DEDENT = {f='dedent'}

function totext(v)
	if v:sub(1,1)=="'" then
		return true
	end
end

-- todo exponent
function isnumber(v)
	if not v then return false end

	-- manual override
	if v:match('%-?[%dABCDEF][%.%dABCDEF]*') == v then
		return true
	else
		return false
	end

	-- hex
	if v:match('[%dABCDEF]+[xh]') then
		return true
	elseif v:match('[01]*e?[01]*b') or v:match('[01]*%.[01]*e?[01]*b')  then
		return true

	-- decimal
	--elseif v:match('%-?%d*%.?%d*e?%-?%d*d?') and v:match('%d') then
	elseif v:match('$[-%dABCDEF].*') then
		return true

	-- quaternair
	elseif v:match('[0123]+%.?[0123]*') then
		return true

	end

	return false
end


local sasrules = {
	sas = r'block1',
	exp = alt{ r'pureexp', r'userfunction', r'atom' },
	pureexp = alt{ r'if', r'brackets', r'function', },
	atom = alt{ r'list', r'set', r'number', r'symbol', r'text' },
	brackets = cat{ l'(', r'exp', l')' },
	block1 = mul( cat{ mul(l'\n'), r'exp', l'\n' } ),

	-- 'function', 'symbol', 'number', 'text', 'data', 'brackets', 'logicblock'},
	number = fn(function (tokens)
		if isnumber(peek(tokens)) then
			local v = pop(tokens)
			return v,tokens
		end
	end),
	text = fn(function (tokens)
		if peek(tokens) and totext(peek(tokens)) then
			local v = pop(tokens)
			return v,tokens
		end
	end),
	symbol = fn(function (tokens)
			if peek(tokens) and peek(tokens):match('%a.*') == peek(tokens) then
				local v = pop(tokens)
				return v,tokens
			end
		end),
	indent = fn(function (tokens)
			if peek(tokens) and peek(tokens):match('(\t+)') == peek(tokens) and #peek(tokens) == tokens.indent then
				local v = pop(tokens)
				return v,tokens
			end
		end),
	freeindent = fn(function (tokens)
			if peek(tokens) and peek(tokens):match('(\t+)') == peek(tokens) then
				local v = pop(tokens)
				return v,tokens
			end
		end),

	list = cat{ l'[', r'collection', q(r'indent'), l']'},
	set = cat{ l'{', r'collection', q(r'indent'), l'}'},
	item = r'exp',

	linesep = cat{ l'\n', r'indent' },
	sep = alt{ r'linesep', l',' },
	collection = cat {
		INDENT,
		q(r'linesep'),
		q(r'item'),
		mul( cat{ r'sep', r'item'} ),
		-- consumeer het einde
		mul(l'\n'),
		DEDENT,
	},

	-- functie
	binop = alt{
		l'.',
		l'*', l'/', l'%',
		l'+', l'-',
		l'=', l'!=', l'>', l'<', l'>=', l'<=', l'~=',  
		l'..', l'->', l'is', l':',
		l'@',
		l',',
	},
	unop = alt {
		l'-', l'+-', l'+', l'^', l'_', l'#',
	},
	['function'] = alt{ r'func1', r'func2' },
	func1 = cat{ r'unop', r'exp' },
	func2 = cat{ r'atom', r'binop', r'exp' },
	userfunction = alt{
		cat{ r'atom', r'symbol', r'atom' },
		cat{ r'atom', r'symbol', r'pureexp' },
		cat{ r'symbol', r'pureexp' },
		cat{ r'symbol', r'symbol' },
		--cat{ r'atom' },
	},

	-- if
	['if'] = alt{ r'inlineif', r'blockif', r'ruleif' },
	blockif = cat{
		l'if', r'exp', r'block',
		mul( cat{ l'\n', l'elseif', r'exp',  r'block' } ),
		q( cat{ l'\n', l'else', r'block' } ),
	},
	inlineif = cat{ l'if', r'exp', l'then', r'exp', },
	ruleif = cat{
		l'if', r'block', l'\n',
		l'then', r'block', l'\n',
		l'else', r'block', l'\n',
	},
	block = cat{ INDENT, mul(cat{ l'\n', r'indent', r'exp' }), DEDENT },
}

local keywords = set{
	'if', --[['else',]] 'elseif',
	'as', 'in', 'is',
}
local rulename = '?'
local defrules
defrules = {
	['SAS-ID'] = fn(function(tokens)
		local a,b = defrules.IDENTIFIER.v(tokens)
		if a and not keywords[a] then return a,b end
	end),
	DEBUG = fn(function (tokens)
		print('[DEBUG] Regel: '..color.purple..rulename..
			color.white..', tokens: '..color.cyan..
			tostring(escape(peek(tokens,0)))..' '..color.green..
			tostring(escape(peek(tokens,1)))..' '..color.yellow..
			tostring(escape(peek(tokens,2)))..color.white
			)
		return true,tokens
	end),
	INDENT = fn(function (tokens)
		tokens.indent = (tokens.indent or 0) + 1
		return true,tokens
	end),
	DEDENT = fn(function (tokens)
		tokens.indent = (tokens.indent or 0) - 1
		return true,tokens
	end),
	NUMBER = fn(function (tokens)
		if peek(tokens) and isnumber(peek(tokens)) then
			local v = pop(tokens)
			return v,tokens
		end
	end),
	STRING = fn(function (tokens)
		if peek(tokens) and totext(peek(tokens)) then
			local v = pop(tokens)
			return v,tokens
		end
	end),
	IDENTIFIER = fn(function (tokens)
			if peek(tokens) and peek(tokens):match('%a[%w%-]*') == peek(tokens) then
				local v = pop(tokens)
				return v,tokens
			end
		end),
	COMMENT = fn(function (tokens)
			if peek(tokens) and peek(tokens):sub(1,1) == ';' then
				local v = pop(tokens)
				return v,tokens
			end
		end),
	indent = fn(function (tokens)
			-- niets
			if not peek(tokens) then
				if tokens.indent > 0 then
					return false
				else
					return true,tokens
				end
			end
			if (tokens.indent or 0) == 0 then
				return true,tokens
			end

			local tabs = peek(tokens):match('^(\t+)$')
			if not tabs then return false end

			if #tabs == tokens.indent then
				local v = pop(tokens)
				return v,tokens
			else
				return false
			end
		end),
	freeindent = fn(function (tokens)
			if peek(tokens) and peek(tokens):match('(\t+)') == peek(tokens) then
				local v = pop(tokens)
				return v,tokens
			end
		end),
}
for k,v in pairs(defrules) do
	defrules[v] = k
end

local ebnf_exp
function unebnf(rules)
	local r = {}
	local indent = 0
	for k,v in pairs(rules) do
		if type(k) == 'string' and #k > indent then
			indent = #k
		end
	end
	for k,v in spairs(rules) do
		if k ~= 1 then
			table.insert(r, k)
			table.insert(r, ':')
			table.insert(r, string.rep(' ', indent - #k + 1))
			table.insert(r, ebnf_exp(v))
			table.insert(r, '\n')
		end
	end
	return table.concat(r)
end

local unop = {opt = '?', plus = '+', mul = '*'}
function ebnf_exp(rule)
	if rule.f == 'fn' then return '<FN>' end
	if rule.f == 'indent' then return 'INDENT' end
	if rule.f == 'dedent' then return 'DEDENT' end
	if rule.f == 'ref' then return rule.v end
	if rule.f == 'lit' then return '"'..escape(rule.v)..'"' end
	if rule.f == 'cat' or rule.f == 'alt' then
		local r = {}
		for i,v in ipairs(rule.v) do
			table.insert(r, ebnf_exp(v))
			if i ~= #rule.v then
				if rule.f == 'cat' then
					table.insert(r, ' ')
				else
					table.insert(r, ' | ')
				end
			end
		end
		return table.concat(r)
	end
	if rule.f == 'opt' or rule.f == 'mul' or rule.f == 'plus' then
		if atom(rule.v) then
			return rule.v .. unop[rule.f]
		else
			return '('..ebnf_exp(rule.v)..')'..unop[rule.f]
		end
	end
	print(unparseSexp(rule))
	error('uhh...' .. rule.f)
end

-- recursive descent
-- 'a + 3' parse sas
function recdesc(rules, rule, tokens)
	rulename = rules[rule] or rulename 
	local tokens = copy(tokens)

	-- direct comparison
	if rule.f == 'lit' then
		local v = peek(tokens)
		if v == rule.v then
			pop(tokens)
			return rule.v, tokens
		else
			return false
		end
	end

	-- optioneel (?)
	if rule.f == 'opt' then
		local v,tokens1 = recdesc(rules, rule.v, tokens)
		if v then
			return v,tokens1
		else
			return '',tokens
		end
	end

	-- nul of meer (*)
	if rule.f == 'mul' then
		local res = {}
		local v,tokens1 = recdesc(rules, rule.v, tokens)
		while v do
			tokens = tokens1
			if v ~= true then
				table.insert(res, v)
			end
			v,tokens1 = recdesc(rules, rule.v, tokens)
		end
		return res, tokens
	end

	-- een of meer (+)
	if rule.f == 'plus' then
		local v,tokens1 = recdesc(rules, rule.v, tokens)
		if v then
			local res = {}
			while v do
				tokens = tokens1
				if v ~= true then
					table.insert(res, v)
				end
				v,tokens1 = recdesc(rules, rule.v, tokens)
			end
			return res, tokens
		else
			return false
		end
	end

	-- reference
	if rule.f == 'ref' then
		local ref = rules[rule.v] or defrules[rule.v]
		if not ref then
			error('ongebonden regel '..rule.v)
		end

		return recdesc(rules, ref, tokens)
	end

	-- alternatives
	if rule.f == 'alt' then
		for i,alt in ipairs(rule.v) do
			local v,t = recdesc(rules, alt, tokens)
			if v then
				return v,t
			end
		end
		return false
	end

	-- concatenate
	if rule.f == 'cat' then
		local res = {}
		for i,v in ipairs(rule.v) do
			local a,tokens1 = recdesc(rules, v, tokens)
			if a then
				tokens = tokens1
				if a ~= true then -- negeer pure uitkomsten
					table.insert(res, a)
				end
			else
				return false
			end
		end
		return res, tokens
	end

	-- indentatie
	if rule.f == 'indent' then
		tokens.indent = (tokens.indent or 0) + 1
		return true,tokens
	end
	if rule.f == 'dedent' then
		if not tokens.indent then
			print('dedent ongeldig')
		end
		tokens.indent = tokens.indent - 1
		return true,tokens
	end

	-- functie
	if rule.f == 'fn' then
		return rule.v(tokens)
	end

	print('ONGELDIGE REGEL')
	print(rule.f)
	print(unparseSexp(rule))
	for k,v in pairs(rule[1]) do print('kv',k,v) end
	print('rule', unparseSexp(rule.f))
	error('onbekende operatie '..(rule.f or tostring(rule)))
end

function parse(ebnf, tokens)
	local tokens = {v=tokens, i=1}
	return recdesc(ebnf, ebnf[1], tokens)
end

require 'sexp'

local rules = {
	STRING = fn(function (tokens)
		if peek(tokens) and totext(peek(tokens)) then
			local v = pop(tokens)
			return v,tokens
		end
	end),
	IDENTIFIER = fn(function (tokens)
			if peek(tokens) and peek(tokens):match('%a.*') == peek(tokens) then
				local v = pop(tokens)
				return v,tokens
			end
		end),
	COMMENT = fn(function (tokens)
			if peek(tokens) and peek(tokens):sub(1,1) == ';' then
				local v = pop(tokens)
				return v,tokens
			end
		end),

	ebnf = mul( r'rule' ),
	rule = cat{ r'IDENTIFIER', l':', r'exp', },
	atom = alt{ r'STRING', r'IDENTIFIER', r'brackets' },
	brackets = cat{ l'(', r'exp', l')' },
	postfix = alt{ l'+', l'*', l'?' },
	exp = cat{ r'atom', q(r'postfix'), mul(cat{ q(l'|'), r'exp'}) }
}
rules = lisp(file('ebnf/ebnf.lisp'))
for k,v in pairs(rules) do rules[v] = k end

--[[
total-rescues =
	+ high-rescues
	+ medium-rescues
	+ low-rescues
]]
local toexp
local function toatom(chunk)
	if atom(chunk) then
		return chunk
	else
		return toexp(chunk[2])
	end
end

-- twee mogelijkheden: haakjes of niet!
function toexp(chunks)
	local r = toatom(chunks[3])

	-- postfix
	if chunks[4] ~= '' then
		r = {chunks[4], r}
	end

	-- binops
	if chunks[5] ~= '' then
		--print('chunk',unlisp(chunks))
		--local op = chunks[5][2][1]
		local op = chunks[5][2]
		if op == '' then op = '||' end
		local sub = toexp(chunks[5])
		if sub[1] == op then
			-- copy
			table.insert(sub, 2, r)
			r = sub
		else
			r = {op, r, sub}
		end
	end

	return r
end

-- PARSE RESULTAAT -> S-EXP
local function totree(chunk)
	local rules = {}
	for i,chunk in ipairs(chunk) do
		--print('S-EXP: '..unlisp(chunk[3]))
		
		local name = chunk[1]
		local exp = toexp(chunk[3])
		table.insert(rules, {name, exp})
	end
	return rules
end

local function torule(sexp)
	if atom(sexp) then
		if sexp:sub(1,1) == "'" then
			return l(sexp:sub(2,-2))
		else
			return r(sexp)
		end
	else
		local t = {}
		for i=2,#sexp do
			t[i-1] = torule(sexp[i])
		end
		if sexp[1] == '||' then
			return cat(t)
		elseif sexp[1] == '|' then
			return alt(t)
		elseif sexp[1] == '-' then
		print('ja')
			return sub(t)
		elseif sexp[1] == '?' then
			return q(t[1])
		elseif sexp[1] == '*' then
			return mul(t[1])
		elseif sexp[1] == '+' then
			return plus(t[1])
		end
	end
end

local function torules(sexp)
	local rules = {}
	for i,rule in ipairs(sexp) do
		rules[rule[1]] = torule(rule[2])
		if i == 1 then
			rules[i] = r(rule[1])
		end
	end
	-- debug
	for k,v in pairs(rules) do
		rules[v] = k
	end
	return rules
end

local lebnf = lisp(file('ebnf/ebnf.lisp'))
local rebnf = torules(lebnf)

-- hele functie
function ebnf(e)
	local tokens = lex(e)
	local chunk = parse(rebnf, tokens)
	local tree = totree(chunk)
	local rules = torules(tree)
	return rules
end

-- zelf test
do
	local chunk1 = parse(rebnf, lex(file('ebnf/ebnf.ebnf')))
	local lebnf1 = totree(chunk1)
	local rebnf1 = torules(lebnf1)

	if lispNeq(lebnf, lebnf1) then
		print('EBNF:')
		print(unebnf(rebnf1))
		print()
		print('LISP:')
		print(unebnf(rebnf))
		error('EBNF is niet consistent met LISP TUSSENREPRESENTATIE')
	end
end
