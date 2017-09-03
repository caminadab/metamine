require 'sas'
require 'util'
local insert = table.insert
local remove = table.remove
local unpack = table.unpack
local concat = table.concat
local find = string.find
local floor = math.floor

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
	['='] = function (a,b) return tosas(a) == tosas(b) end;
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

	-- cond
	['=>'] = function (a,b) if a then return b else return nil end end;
	['&']  = function (a,b) return a or b end;
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

-- make sas (= string) object
function tosas(v)
	if type(v) == 'boolean' then
		return tostring(v)
	elseif type(v) == 'string' then
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

-- make lua object
function tolua(v)
	if type(v) ~= 'string' then
		return v
	end
	if v == 'false' then
		return false
	elseif v == 'true' then
		return true
	elseif tonumber(v) then
		return tonumber(v)
	elseif istext(v) then
		return gettext(v)
	elseif v:sub(1,1) == '[' then
		local res = tail(multi(parse(v), ','))
		for i,v in ipairs(res) do
			res[i] = tolua(v)
		end
		return res
	else
		return nil
	end
end

function interpret2(prog)
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
				elseif src == 'true' then
					arg = true
				elseif src == 'false' then
					arg = false
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

					ret[i] = tosas(fn(table.unpack(sargs)))
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

assert(unparseSexp(multi(parse('1 + 2 + 3 + 4'), '+')) == unparseSexp(parseSexp('(+ 1 2 3 4)')))
assert(unparseSexp(multi(parse('1'), '+')) == unparseSexp(parseSexp('(+ 1)')))

function replace(sexp, dst, src)
	if unparseSexp(sexp) == unparseSexp(src) then
		return dst, true
	elseif atom(sexp) then
		return sexp
	else
		local ok = false
		for i,v in ipairs(sexp) do
			local ok1
			sexp[i],ok1 = replace(v, dst, src)
			if ok1 then
				ok = true
			end
		end
		return sexp, ok
	end
end

function isname(sexp)
	return atom(sexp) and string.match(sexp:sub(1,1), '%a')
end

function isconstant(sexp)
	if sexp == 'true' or sexp == 'false' then
		return true
	elseif atom(sexp) then
		return not not string.match(sexp:sub(1,1), '[%-%d\']')
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
o1 || i1 = i2	=>	o1 = i2.[0..(#i2-#i1)] ;and i1 = i2.[#i2-#i1..#i2]
i1 || o1 = i2	=>	i1 = i2.[0..#i1] and o1 = i2.[#i1..#i2] ;and i1 = i2.[0..#i1]
o1 || i1 || o2 = i2	=>	o1 = i2.[0..find(i2,i1)] and o2 = i2.[find(i2,i1) + #i1 .. #i2]
o1 || o2 = i1	=>	#o1 + #o2 = #i1

; lijsten
;o1.i1 = i2		=>	o1 = i2

; cond
;o1 = i1 | false	=> o1 = i1
;o1 = false | i1	=> o1 = i1
o1 = o2 | o3	=>	o1 = o2 or o1 = o3

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
			print()
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

	-- oeps!
	elseif sexp[1] == 'or' then
		-- "pretend"
		local options = {'or'}
		local stats = multi(sexp, 'or')
		for i=2,#stats do
			local option = stats[i]
			local res = solve(option)
			if res then
				insert(options, res)
			end
			return unmulti(options)
		end

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
			if not vals[i] then insert(res, 'NONE')
			else
				
				--insert(res, unparse(vals[i]))
			end
		end
		insert(res, '\n')
	end
	return table.concat(res)
end

function fastEval(sexp)
	local prog = compile(sexp)
	return interpret(prog, fnArith)
end

function neq(a,b)
	return isconstant(a) and isconstant(b) and tostring(fastEval(a)) ~= tostring(fastEval(b))
end

function eq(a,b)
	return isconstant(a) and isconstant(b) and tostring(fastEval(a)) == tostring(fastEval(b))
end

function solveSystem(sexp)
	local eqs = multi(sexp, 'and')
	local ok = true
	while ok do
		ok = false

		-- substitute
		for i=2,#eqs do
			local src = eqs[i]
			if src == 'false' then
				return 'false'
			elseif src == 'true' or eq(src[2], src[3]) then
				remove(eqs,i)
			else
				for j=2,#eqs do
					if i~=j then
						local dst = eqs[j]
						if src[1] == '=' and isconstant(src[3]) then
							local ok1
							dst,ok1 = replace(dst, src[3], src[2])
							if isconstant(dst[2]) then
								dst[2],dst[3] = dst[3],dst[2]
							end

							if ok1 then
								ok = true
								log('continue because ',src,dst)
							end
							eqs[j] = dst
						end
						-- single false
						if neq(src[2],src[3]) then
							print('false',unparseSexp(src))
							return 'false'
						end
					end
				end
			end
		end

		-- solve
		for i=2,#eqs do
			eqs[i] = solveEquation(eqs[i])
		end
	end
	return unmulti(eqs)
end

local fnSolve = {
	['='] = function (sexp)
		if isconstant(sexp[2]) and isconstant(sexp[3]) then
			return tostring(unparseSexpCompact(sexp[2]) == unparseSexpCompact(sexp[3]))
		end
		return solveEquation(clone(sexp))
	end;
	['=>'] = function (sexp)
		local op,cond,act = unpack(sexp)
		local cnf = multi(cond, 'or')
		local options = {j}
		for i=2,#cnf do
			local act = clone(act)
			local case = cnf[i]
			local stats = multi(case, 'and')
			for i=2,#stats do
				local stat = stats[i]
				if stat == 'false' then
					return 'false'
				end
				local op,src,dst = unpack(stat)
				if op == '=' then
					act = replace(act, dst, src)
				end
			end
			options[unparseSexpCompact(act)] = act
			-- insert(options, act)
		end

		local options1 = {'|'}
		for k,v in pairs(options) do
			insert(options1, v)
		end

		return unmulti(options1)
	end;
	['or'] = function (sexp)
		if sexp[2] == 'true' then return sexp[3] end
		if sexp[3] == 'true' then return sexp[2] end
		if sexp[2] == 'false' and sexp[3] == 'false' then
			return 'false'
		else
			return sexp
		end
	end;
	['and'] = function (sexp)
		local stats = multi(sexp, 'and')
		local all = {'and'}
		local total = 1
		local cond = {'or'}
		for i=2,#stats do
			local stat = stats[i]
			if stat == 'false' then
				return 'false'
			end
			all[i] = multi(stat, 'or')
			total = total * (#all[i]-1)
		end
		for i=1,total do
			local stat = {'and'}
			local index = i-1
			for j=2,#all do
				local index1 = index % #all[j]
				index = floor(index / #all[j])
				insert(stat, all[j][index1+1+1])
			end
			local system = unmulti(stat)
			local solved = solveSystem(system)
			if solved ~= 'false' then
				insert(cond, solved)
			end
		end
		if #cond == 1 then
			return 'false'
		end
		return unmulti(cond)
	end;
}

fnArith = {
	['+'] = function (sexp) return sexp[2] + sexp[3] end;
	['-'] = function (sexp) return sexp[2] - sexp[3] end;
	['/'] = function (sexp) return sexp[2] / sexp[3] end;
	['*'] = function (sexp) return sexp[2] * sexp[3] end;
	['^'] = function (sexp) return sexp[2] ^ sexp[3] end;
	['='] = function (sexp) return sexp[2] == sexp[3] end;
	['and'] = function (sexp) return tostring(tolua(sexp[2]) and tolua(sexp[3])) end;
	['or'] = function (sexp) return tostring(tolua(sexp[2]) or tolua(sexp[3])) end;
	['#'] = function (sexp) return #sexp[2]-2 end;
	['..'] = function(sexp)
		local a,b = sexp[2],sexp[3]
		local res = {}
		for i=a,b-1 do
			insert(res, i)
		end
		return res
	end;
	[','] = function(sexp)
		local a,b = sexp[2],sexp[3]
		if type(a) == 'table' then
			local a = clone(a)
			insert(a,b)
			return a
		else
			return {a,b}
		end
	end;

	['||'] = function(sexp) 
		local a,b = sexp[2],sexp[3]
		return a .. b
	end;


	['.'] = function(sexp)
		local a,b = sexp[2],sexp[3]
		if type(a) == 'table' and type(b) == 'number' then
			return a[b+1]
		end
		local res = {}
		for i,v in ipairs(b) do
			if type(a) == 'string' then
				insert(res, a:sub(v+2,v+2))
			elseif type(a) == 'number' then
				return 'index-dot'
			else
				insert(res, a[v+1])
			end
		end
		if type(a) == 'string' then
			return totext(concat(res))
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
}

function getvar(v)
	return v and string.match(v, 'v(%d+)')
end

function interpret(prog, fn)
	local res = {}
	for i,cmd in ipairs(prog) do
		if atom(cmd) then
			res[i] = cmd
		else
			local op,a,b = unpack(cmd)
			if getvar(a) then a = res[tonumber(getvar(a)) + 1] end
			if getvar(b) then b = res[tonumber(getvar(b)) + 1] end

			if not fn[op] then
				res[i] = {op,a,b}
			else
				res[i] = fn[op]{op,a,b}
				if type(res[i]) == 'number' then
					res[i] = tostring(res[i])
				end
			end
			--log('v'..i-1 ..' = ',res[i])
		end
	end
	return res[#res], res
end

local src = [[
v = s | i
bv = bs | bi
bs = #s || ':' || s
bi = 'i' || i || 'e'
bs
]]

--[[
INPUT: bv
bv = bs | bi

bs = #s || ':' || s
#s = bs.[0..find(bs,':')]
s = bs.[find(bs,':') .. #bs]

bi = 'i' || i || 'e'
i = bi.[1..#bi-1]
bi.1 = 'i'
bi.#bi = 'e'

bv : bs			<= bv.1 = 'i'

bv.1 = 'i'	=> i = bi.[1..#bi-1]
bv.1 != 'i'	=> s = bs.[find(bs,':') .. #bs]

]]

-- SOURCE
print('Source:')
print(src)
print()

-- RUN IT
local prog = compile(parse(src))
local res,vals = interpret(prog,fnSolve)
print('Solved:')
print(unparseProg(prog,vals))
print('= '..unparse(res))
print()

-- RESULT
local prog = compile(res)
local res,vals = interpret(prog,fnArith)
print('Compiled:')
print(unparseProg(prog,vals))
print('= '..unparse(res))
print()

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

