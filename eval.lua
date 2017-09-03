require 'sas'
require 'util'
local insert = table.insert
local remove = table.remove
local unpack = table.unpack
local concat = table.concat
local find = string.find

local op = {
	['+'] = function (a,b) return a + b end;
	['-'] = function (a,b) if not b then return -a else return a - b end end;
	['*'] = function (a,b) return a * b end;
	['/'] = function (a,b) return b~=0 and a / b or 'oo' end;
	['^'] = function (a,b) if b then return a ^ b else return math.exp(a) end end;
	['_'] = function (a,b) if b then return math.log(a) / math.log(b) else return math.log(a) end end;

	['>'] = function (a,b) return a > b end;
	['<'] = function (a,b) return a < b end;
	['>='] = function (a,b) return a >= b end;
	['=<'] = function (a,b) return a <= b end;
	['='] = function (a,b) return a == b end;
	['%'] = function (a,b) return a % b end;

	['sin'] = math.sin;
	['cos'] = math.cos;
	['tan'] = math.tan;
	['asin'] = math.asin;
	['acos'] = math.acos;
	['atan'] = math.atan;
	['sqrt'] = function(a) if a < 0 then error('imaginaire getallen? nee nog niet') else return math.sqrt(a) end end;
	['cbrt'] = function (a) return math.pow(a, 1/3) end;

	['+-'] = function (a,b) error('opties nog niet ondersteund') end;
	['|'] = function (a,b) error('opties nog niet ondersteund') end;

	['#'] = function(a) return #a end;
	['..'] = function(a,b)
		local res = {}
		for i=a,b-1 do
			insert(res, i)
		end
		return res
	end;
	[','] = function(a,b)
		if type(a) == 'table' then
			local a = clone(a)
			insert(a,b)
			return a
		else
			return {a,b}
		end
	end;

	['||'] = function(a,b) return a .. b end;

	['.'] = function(a,b)
		if type(a) == 'table' and type(b) == 'number' then
			return a[b+1]
		end
		local res = {}
		for i,v in ipairs(b) do
			if type(a) == 'string' then
				insert(res, a:sub(v+1,v+1))
			elseif type(a) == 'number' then
				return 'index-dot'
			else
				insert(res, a[v+1])
			end
		end
		if type(a) == 'string' then
			return concat(res)
		else
			return res
		end
	end;

	['concat'] = concat;
	['find'] = function(a)
		local str,sub = unpack(a)
		local pos = find(str, sub, 0, true)
		if not pos then
			return false
		end
		return pos - 1
	end;

	['>>'] = function(a,b)
		if b == 'text' then
			return totext(a)
		end
	end;
}

function isnumber(sexp)
	return tonumber(sexp)
end
function istext(sexp)
	return atom(sexp) and sexp:sub(1,1)=="'" and sexp:sub(-1)=="'"
end
function gettext(sexp)
	return sexp:sub(2,-2)
end
function totext(sexp)
	return "'"..sexp.."'"
end

function tosas(v)
	if type(v) == 'string' then
		return totext(v)
	elseif type(v) == 'number' then
		return tostring(v)
	elseif type(v) == 'table' then
		local res = {}
		insert(res, '[')
		for i,n in pairs(v) do
			insert(res, tosas(n))
			if next(v,i) then
				insert(res, ',')
			end
		end
		insert(res, ']')
		return table.concat(res, '')
	else
		return 'none'
	end
end

function interpret(prog)
	-- bevat echte waarden
	local res = {}
	for i,v in ipairs(prog) do
		if atom(v) then
			res[i] = v
		else
			local args = {}
			local fn
			fn = op[v[1]]
			if not fn then error('onbekende functie '..v[1]) end
			for i=2,#v do
				local src = v[i]
				local arg
				if isnumber(src) then
					arg = tonumber(src)
				elseif istext(src) then
					arg = gettext(src)
				else
					local index = tonumber(src:sub(2))
					if not index then
						error('onbekende naam '..src)
					end
					arg = res[index + 1]
					if not arg then
						--break
						--error('ongeldige variabele '..src)
					end
				end
				insert(args,arg)
			end
			local ret 
			if false and v[1] ~= ',' and v[1] ~= '#'  and type(args[1]) == 'table' then
				local sargs = clone(args)
				ret = {}
				for i,v in ipairs(args[1]) do
					sargs[1] = v
					log('fn',sargs)

					ret[i] = fn(table.unpack(sargs))
				end
			else
				pcall(function()
					ret = fn(table.unpack(args))
				end)
			end
			res[i] = ret
		end
	end

	return res[#res], res
end

-- maakt lijst van expressies
-- (* (+ 1 2) 3)
function compile(sexp)
	local res = {}

	local function work(sexp)
		-- ten eerste onze argumenten
		local self = {}--sexp[1]}
		for i=1,#sexp do
			local arg = sexp[i]
			if exp(arg) then
				work(arg)
				self[i] = 'v'..#res-1
			else
				self[i] = sexp[i]
			end
		end

		insert(res, self)
	end

	if atom(sexp) then
		if isname(sexp) then
			--error('ongebonden variabele '..sexp)
		end
		insert(res, sexp)
	else
		work(sexp)
	end

	return res
end

-- 1 + 2 + 3 + 4 -> (+ 1 2 3 4)
function multi(sexp, op)
	local res = {op}
	local cur = sexp
	while cur[1] == op do
		insert(res, 2, cur[3])
		cur = cur[2]
	end
	-- laatste
	insert(res, 2, cur)
	return res
end

assert(unparseSexp(multi(parse('1 + 2 + 3 + 4'), '+')) == unparseSexp(parseSexp('(+ 1 2 3 4)')))
assert(unparseSexp(multi(parse('1'), '+')) == unparseSexp(parseSexp('(+ 1)')))

-- (+ 1 2 3 4) -> 1 + 2 + 3 + 4
function unmulti(sexp)
	local op = sexp[1]
	if #sexp == 2 then
		return sexp[2]
	else
		local cur = {op, sexp[2], sexp[3]}
		for i=4,#sexp do
			cur = {op, cur, sexp[i]}
		end
		return cur
	end
end

function replace(sexp, dst, src)
	if unparseSexp(sexp) == unparseSexp(src) then
		return dst
	elseif atom(sexp) then
		return sexp
	else
		for i,v in ipairs(sexp) do
			sexp[i] = replace(v, dst, src)
		end
		return sexp
	end
end

function isname(sexp)
	return atom(sexp) and string.match(sexp:sub(1,1), '%a')
end

function isconstant(sexp)
	if atom(sexp) then
		return string.match(sexp:sub(1,1), '[%-%d\']')
	else
		local c = true
		for i=2,#sexp do
			if not isconstant(sexp[i]) then
				c = false
				break
			end
		end
		return c
	end
end

-- a+2=3 => a=3-2
local solutions = parse[[
o1 + i1 = i2	=>	o1 = i2 - i1
i1 + o1 = i2	=>	o1 = i2 - i1
o1 - i1 = i2	=>	o1 = i2 + i1
i1 - o1 = i2	=>	o1 = i1 - i2
i1 = -o1			=>	o1 = -i1

o1 * i1 = i2	=>	o1 = i2 / i1
i1 * o1 = i2	=>	o1 = i2 / i1
o1 / i1 = i2	=>	o1 = i2 * i1
i1 / o1 = i2	=>	o1 = i1 / i2
i1 / o1 = i2	=>	o1 = i1 / i2

o1 ^ i1 = i2	=>	o1 = i2 ^ (1/i1)
i1 ^ o1 = i2	=>	o1 = i2 _ i1

sin o1 = i1		=>	o1 = asin i1
cos o1 = i1		=>	o1 = acos i1

; tekst
; #o1 + #i1 = #i2
o1 || i1 = i2	=>	o1 = i2.[0..(#i2-#i1)]
i1 || o1 = i2	=>	o1 = i2.[#i1..#i2]
o1 || i1 || o2 = i2	=>	o1 = i2.[0..find(i2,i1)] and o2 = i2.[find(i2,i1) + #i1 .. #i2]
o1 || o2 = i1	=>	#o1 + #o2 = #i1

; lijsten
;o1.i1 = i2		=>	o1 = i2

true
]]
local solutions = multi(solutions[2], 'and')

function matchIO(what, to, bindings)
	bindings = bindings or {}
	if exp(to) then
		if atom(what) then
			return false -- niet complex genoeg
		else
			-- allebei exp
			if #what ~= #to then
				return false -- verschillend aantal
			end
			for i=1,#to do
				local res = matchIO(what[i], to[i], bindings)
				if not res then
					return false -- subs matchtde niet
				end
			end
			return bindings
		end
	else
		local input = to:sub(1,1) == 'i'
		local output = to:sub(1,1) == 'o'
		if input then
			if isconstant(what) then
				if bindings[to] and unparseSexpCompact(bindings[to]) ~= unparseSexpCompact(what) then
					return false -- mismatch
				end
				bindings[to] = what
				return bindings
			else
				return false -- niet input want niet constant!!
			end
		elseif output then
			bindings[to] = what
			return bindings
		elseif what == to then
			return bindings -- waar, geen toevoegingen
		else
			return false -- matcht niet atomair
		end
	end
end

function clone(sexp)
	if atom(sexp) then
		return sexp
	else
		local res = {}
		for i,v in ipairs(sexp) do
			res[i] = clone(v)
		end
		return res
	end
end

function halfSolveEquation(eq)
	local ok = false
	for i=2,#solutions do
		local solution = solutions[i]
		local bindings = matchIO(eq, solution[2])
		if bindings then
			ok = true
			eq = clone(solution[3])
			for k,v in pairs(bindings) do
				eq = replace(eq, v, k)
			end
			local after = unparseInfix(eq)
			print('<= '..unparseInfix(solution[2]))
			print('=> '..after)
		end
	end
	return eq, ok
end

function solveEquation(eq)
	-- ga door zolang we verbeteren - geschat O(N*M) waarbij M aantal regels is.
	local anyok = false
	local ok = true
	while ok do
		ok = false

		-- links-rechts
		local eq1,ok1 = halfSolveEquation{eq[1],eq[2],eq[3]}
		if ok1 then
			ok = true
			anyok = true
			eq = eq1
		end

		-- andersom
		local eq2,ok2 = halfSolveEquation{eq[1],eq[3],eq[2]}
		if ok2 then
			ok = true
			anyok = true
			eq = eq2
		end
	end
	return eq,anyok
end

function imulti(a)
	local i = 2 - 1
	return function()
		i = i + 1
		return a[i], i-1
	end
end

function log(...)
	local l = {...}
	for i,v in ipairs(l) do
		io.write(unparse(v))
		io.write('\t')
	end
	io.write('\n')
end

function solve(sexp)
	-- oplossingsgericht procesbeheer
	if sexp[1] == '=>' then
		local res = sexp[3]
		local bindings = solve(sexp[2])
		stats = multi(bindings, 'and')
		for i,stat in ipairs(stats) do
			if stat[1] == '=' then
				local n,v = stat[2],stat[3]
				if isname(v) then
					n,v = v,n
				end
				res = replace(res, v, n)
			end
		end
		return res

	-- standaard vergelijkingen
	elseif sexp[1] == 'and' or sexp[1] == '=' then
		local stats = multi(sexp, 'and')
		local ok = true

		while ok do
			ok = false
			-- A = 3 VERVANGING!!!!
			for i,eqSrc in ipairs(stats) do
				for j,eqDst in ipairs(stats) do
					if i>1 and j>1 and i~=j then
						
						-- we kunnen vervangen nu?
						if eqSrc[1] == '=' and not isconstant(eqSrc[2]) then
							stats[j] = replace(stats[j], eqSrc[3], eqSrc[2])
						end
					end
				end
			end

			-- herleid nieuwe feiten
			for i,stat in ipairs(stats) do
				local eqs,ok1 = solveEquation(stats[i])
				local eqs = multi(eqs, 'and')
				if ok1 then
					ok = true
					remove(stats, i)
					for i,eq in ipairs(eqs) do
						if i>1 then
							insert(stats, eq)
							log('eq',eq)
						end
					end
				end
			end

		end

		return unmulti(stats)
	end

	return sexp
end


function unparseProg(prog, vals)
	local res = {}
	for i,v in ipairs(prog) do
		insert(res, 'v')
		insert(res, tostring(i-1))
		insert(res, ' := ')
		insert(res, unparseInfix(v))
		if vals then
			insert(res, '\t\t; ')
			insert(res, tosas(vals[i]))
		end
		insert(res, '\n')
	end
	return table.concat(res)
end

function eval(sexp)
	local plain = solve(sexp)
	print(color.purple..'partieel: '..unparse(plain)..color.white)
	local prog = compile(plain)
	local res = interpret(prog)
	return tosas(res)
end

local src = [[
3
]]

print('Source:')
print(src)

local prog = compile(solve(parse(src)))
print('Solved:')
print(unparse(solve(parse(src))))
print()

local res,vals = interpret(prog)
print('Compiled:')
print(unparseProg(prog,vals))

--[[

3 : constant & int & number
(3 + 2) : (int + int)
(3 + 2) : int

(int + int) : int

; type deductie
a: b
b: c
=> a: c

3+2: int+int
int+int: int
=> 3+2: int

]]
