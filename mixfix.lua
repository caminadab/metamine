require 'lex'

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

local function peek(queue,n) local n = n or 0; return queue[1+n] end
local function pop(queue) return table.remove(queue,1) end

--	| list | set | if | function
--	| symbol | number | text | data
--	| '(' exp ')' | logicblock
function pureexp(tokens)
	if tonumber(peek()) then
		return pop()
	end
end

local function alt(t) return {f='alt',v=t} end
local function cat(t) return {f='cat',v=t} end
local function l(t)	return {f='lit',v=t} end -- literal
local function r(t)	return {f='ref',v=t} end -- reference
local function q(t) return {f='opt',v=t} end -- optional / maybe
local function mul(t) return {f='mul',v=t} end -- zero or more
local function plus(t) return {f='plus',v=t} end -- one or more
local function fn(t) return {f='fn',v=t} end -- call function to check
local INDENT = {f='indent'}
local DEDENT = {f='dedent'}

local f
local rules = {
	sas = r'exp',
	exp = r'pureexp', -- 'userfunction'},
	atom = alt{ r'list', r'set', r'number', r'symbol' },
	pureexp = alt{ r'function', r'atom', }, -- r'if', r'number', r'symbol'},
	-- 'function', 'symbol', 'number', 'text', 'data', 'brackets', 'logicblock'},
	number = fn(function (tokens)
		if tonumber(tokens[1]) then
			local v = pop(tokens)
			return v,tokens
		end
	end),
	indent = fn(function (tokens)
			if tokens[1]:match('(\t+)') == tokens[1] and #tokens[1] == tokens.indent then
				local v = pop(tokens)
				return v,tokens
			end
		end),
	freeindent = fn(function (tokens)
			if tokens[1]:match('(\t+)') == tokens[1] then
				local v = pop(tokens)
				return v,tokens
			end
		end),
	symbol = fn(function (tokens)
			if tokens[1]:match('%a.*') == tokens[1] then
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

	['function'] = cat{ r'atom', l'=', r'exp' },

	-- if
	['if'] = cat{ l'if', r'exp', },
}
for k,v in pairs(rules) do
	rules[v] = k
end

function ebnf(rule)
	if rule.f == 'fn' then return '<FN>' end
	if rule.f == 'indent' then return 'INDENT' end
	if rule.f == 'dedent' then return 'DEDENT' end
	if rule.f == 'ref' then return rule.v end
	if rule.f == 'lit' then return '"'..rule.v..'"' end
	if rule.f == 'opt' then return ebnf(rule.v) .. '?' end
	if rule.f == 'alt' then
		local r = {}
		for i,v in ipairs(rule.v) do
			table.insert(r, '(')
			table.insert(r, ebnf(v))
			table.insert(r, ')')
			if i ~= #rule.v then
				table.insert(r, ' | ')
			end
		end
		return table.concat(r)
	end
	if rule.f == 'cat' then
		local r = {}
		for i,v in ipairs(rule.v) do
			table.insert(r, ebnf(v))
			if i ~= #rule.v then
				table.insert(r, ' ')
			end
		end
		return table.concat(r)
	end
	if rule.f == 'mul' then return ebnf(rule.v)..'*' end
	if rule.f == 'plus' then return ebnf(rule.v)..'+' end
	print(unparseSexp(rule))
	error('uhh...' .. rule.f)
end

-- recursive descent
local n = 0
function recdesc(rule, tokens)
	n = n + 1
	if n % 1000 == 999 then
		print(n + 1, ebnf(rule))
	end

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
		local v,tokens1 = recdesc(rule.v, tokens)
		if v then
			return v,tokens1
		else
			return true,tokens
		end
	end
	
	-- een of meer (*)
	if rule.f == 'mul' then
		local res = {}
		local v,tokens1 = recdesc(rule.v, tokens)
		while v do
			if v then tokens = tokens1 end
			if v ~= true then
				table.insert(res, v)
			end
			v,tokens1 = recdesc(rule.v, tokens)
		end
		return res, tokens
	end

	-- reference
	if rule.f == 'ref' then
		if not rules[rule.v] then
			error('ongebonden regel '..rule.v)
		end

		return recdesc(rules[rule.v], tokens)
	end

	-- alternatives
	if rule.f == 'alt' then
		for i,alt in ipairs(rule.v) do
			if recdesc(alt, tokens) then
				return recdesc(alt, tokens)
			end
		end
		return false
	end

	-- concatenate
	if rule.f == 'cat' then
		local res = {}
		for i,v in ipairs(rule.v) do
			local a,tokens1 = recdesc(v, tokens)
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

	print('rule', unparseSexp(rule))
	error('onbekende operatie '..rule.f)
end

function mixfix(tokens)
	return recdesc(rules.sas, tokens)
end

require 'sexp'
local src = [[
a = {1,2,3}
]]

print(unparseSexp(lex(src)))
local tokens = lex(src)
print('RESULTAAT:')
print(unparseSexp(mixfix(tokens)))
-- {f = '+', [1] = 'a', [2] = 'b'}
