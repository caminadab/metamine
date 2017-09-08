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

	['and'] = function (a,b) return a and b end;
	['or'] = function (a,b) return a and b end;
	['xor'] = function (a,b) return a ~= b end;
	['nor'] = function (a,b) return not a and not b end;

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

	['=>'] = function(a,b)
		if a then
			return b
		else
			return false
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
	elseif type(v) == 'boolean' then
		return tostring(v)
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

function tomexp(sexp)
	local res = {}
	local cur = sexp
	while cur[1] == op do
		insert(res, 2, cur[3])
		cur = cur[2]
	end
	-- laatste
	insert(res, 2, cur)
	res.op = sexp[1]
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

function iscertain(sexp)
	if atom(sexp) then
		return true
	else
		if sexp[1] == '|' then
			return false
		end
		for i,v in ipairs(sexp) do
			if not iscertain(v) then
				return false
			end
		end
		return true
	end
end

function isconstant(sexp)
	if sexp == nil then
		error('rommel')
	elseif istext(sexp) then
		return true
	elseif atom(sexp) then
		return string.match(sexp:sub(1,1), '[%-%d\']')
	else
		if sexp[1] == '|' then
			return false
		end
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
local solutions = parse(file('solutions.sas'))
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
	--eq[2] = solve(eq[2])
	--eq[3] = solve(eq[3])

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
			return eq,anyok
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

function binds(xor, name)
	local stats = multi(xor, 'and')
	local res = {}
	for i=2,#stats do
		if stats[i][1] == '=' and stats[i][2] == name then
			return stats[i][3]
		end
	end
	return nil
end

local commutative = {
	['+'] = true, ['and'] = true, ['or'] = true, ['xor'] = true, ['nor'] = true,
}

-- a + b + 0  match  0 + x
-- a*b + c*d  match  x*y+z*w
function multimatch(sexp, src)

end

function simplify(sexp)
	if sexp[1] == 'and' and sexp[2][1] == 'xor' and sexp[3][1] == 'and' then
	end
end

function solve2(sexp)
	if sexp == nil then error('rommel') end
	if isconstant(sexp) then
		return sexp
	end

	log('SOLVE',sexp)
	for i,solution in ipairs(multi(solutions, 'and')) do
		if i > 1 then
			local bindings = {}
			if matchIO(sexp, solution, bindings) then
				log('yeah')
				print(unparseSexp(bindings))
				log(solution)
			end
		end
	end

	-- oplossingsgericht procesbeheer
	if sexp[1] == '=>' then
		local ok
		local res = solve(sexp[3])
		local bindings = solve(sexp[2])
		stats = multi(bindings, 'and')

		local assertions = {'and'}
		for i,stat in ipairs(stats) do
			if stat[1] == '=' then
				local n,v = stat[2],stat[3]
				if isname(v) then
					n,v = v,n
				end
				if isname(n) and iscertain(v) then
					local ok1
					res,ok1 = replace(res, v, n)
					ok = ok or ok1
				end
			end
			if isconstant(stat) then
				insert(assertions, stat)
			end
		end
		if #assertions > 1 then
			local res,ok1 = solve(res)
			ok = ok or ok1
			return {'=>',unmulti(assertions),res}, ok
		else
			return res,ok
		end

	-- enkele
	elseif sexp[1] == '=' then
		return sexp --solveEquation(sexp)

	elseif sexp[1] == '!=' then
		return sexp

	-- orrry
	elseif sexp[1] == 'xor' then
		local opts = multi(sexp, 'xor')
		local ok
		for i=2,#opts do
			local opt = opts[i]
			local eqs,ok1 = solve(opt)
			if ok1 then
				ok = true
				opts[i] = eqs
			end
		end
		return unmulti(opts), ok

	-- stelsel van vergelijkingen
	elseif sexp[1] == 'and' then
		local stats = multi(sexp, 'and')
		local ok = true
		local anyok

		while ok do
			ok = false
			-- A = 3 VERVANGING!!!!
			for i,eqSrc in ipairs(stats) do
				for j,eqDst in ipairs(stats) do
					if i>1 and j>1 and i~=j then
						
						-- we kunnen vervangen nu?
						if eqSrc[1] == '=' and iscertain(eqSrc[3]) and not isconstant(eqSrc[2]) then
							stats[j] = replace(stats[j], eqSrc[3], eqSrc[2])
						end
					end
				end
			end

			-- herleid nieuwe feiten
			for i,stat in ipairs(stats) do
				local eqs,ok1 = solve(stats[i])
				local eqs = multi(eqs, 'and')
				if ok1 then
					ok = true
					anyok = true
					remove(stats, i)
					for i,eq in ipairs(eqs) do
						if i>1 then
							print('eq',unparse(eq))
							print(eq[1])
							insert(stats, eq)
						end
					end
				end
			end

		end

		return unmulti(stats), anyok
	end

	return sexp, false
end

function eval(sexp)
	local plain = solve(sexp)
	print(color.purple..'partieel: ')
	print(unparse(plain)..color.white)
	local prog = compile(plain)
	local res = interpret(prog)
	return tosas(res)
end

local src = [[
v = t | i
bv = bt | bi
bt = #t || ':' || t
bi = 'i' || i || 'e'

bv = '3:hoi'
v
]]

local src = [[
a = 1 | 2
a = 2 | 3
a
]]

print('Source:')
print(src)


local solved = solve(parse(src))
print('Solved:')
print(unparse(solved))
--print(unparse(solve(parse(src)[2])))
print()

local prog = compile(solved)
local res,vals = interpret(prog)
print('Compiled:')
print(unparseProg(prog,vals))

-- multi waarden
assert(eval[[
a = 1 | 2		; a = 1 xor a = 2
a = 2 | 3		; a = 2 xor a = 3
a
]] == '2')

--[[
(a = 1 xor a = 2) and (a = 2 xor a = 3)
(a = 1 and a = 3) xor (a = 2 and a = 2)

(a xor b) and (c xor d)
=> (a and c) xor (a and d) xor (b and c) xor (b and d)
=> (a and (c xor d)) or (b and (c xor d))

]]


