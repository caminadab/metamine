require 'util'
require 'lex'

-- precedence
local pf = tsv(file('precedence.tsv'))
local precedence = {}
local ops = {}
for pre,pops in ipairs(pf) do
	for i,op in ipairs(pops) do
		precedence[op] = -pre
		ops[op] = true
	end
end
precedence['('] = -math.huge

function shuntingyard(tokens, precedence)
	local fns = {}
	local values = {}
	local out = {}

	function fpop()
		local f = fns[#fns]
		fns[#fns] = nil
		return f
	end

	function fpush(f)
		fns[#fns+1] = f
	end

	function fpeek()
		return fns[#fns]
	end

	function opush(a)
		table.insert(out, a)
	end

	for i,token in ipairs(tokens) do
		if ops[token] then
			while fpeek() and precedence[fpeek()] >= precedence[token] do
				opush(fpop())
			end
			fpush(token)
		elseif token == '(' then
			fpush(token)
		elseif token == ')' then
			while fpeek() ~= '(' do
				opush(fpop())
			end
			fpop()
		else -- constant
			opush(token)
		end
	end
	while fpeek() do
		opush(fpop())
	end
	return out
end

function infix(tokens)
	local polish = shuntingyard(tokens, precedence)
	return polish
end

require 'util'
function debug.infix(sas)
	local polish = infix(lex(sas))
	for i,v in ipairs(polish) do
		if ops[v] then
			io.write(color.purple)
		else
			io.write(color.cyan)
		end
		io.write(v, ' ')
	end
	io.write(color.white, '\n')
end

function eval(polish)
	local values = {}
	function push(v)
		table.insert(values, v)
	end
	function pop()
		local v = values[#values]
		values[#values] = nil
		return v
	end
	local fns = {
		['^'] = function (a,b) return a ^ b end;
		['_'] = function (a,b) return math.log(b, a) end;
		['*'] = function (a,b) return a * b end;
		['/'] = function (a,b) return a / b end;
		['%'] = function (a,b) return a % b end;
		['+'] = function (a,b) return a + b end;
		['-'] = function (a,b) return a - b end;
	}

	for i,v in ipairs(polish) do
		if ops[v] then
			local b,a = pop(),pop()
			local c = fns[v](a,b)
			push(c)
		else
			push(tonumber(v))
		end
	end

	return values[1]
end

--[[
1 * 2 + 3
1 2 * 3 +
v0 := 1 * 2
v1 := v0 + 3

1 + 2 * 3
1 2 3 * +

v0 := 2 * 3
v1 := 1 + v0 
]]

function debug.eval(sas)
	return eval(infix(lex(sas)))
end
