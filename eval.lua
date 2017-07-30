require 'pure'
require 'sexp'
require 'sas'
local insert = table.insert
local remove = table.remove

function substitute(sexp, dst, src)
	-- atom
	if atom(sexp) then
		if sexp==src then
			return dst
		else
			return sexp
		end
	
	-- asdf
	else
		local res = {}
		for i,s in ipairs(sexp) do
			if src=='...' and sexp[i]=='...' then
				for j,d in ipairs(dst) do
					table.insert(res, d)
				end
			else
				local s = substitute(sexp[i], dst, src)
				table.insert(res, s)
			end
		end
		return res
	end
end

local s,p,u = substitute,parseSexp,unparseSexpCompact
assert( s(p'a', p'1', p'a') == p'1' )
assert( u(s(p'(+ a a)', p'1', p'a'))
	== '(+ 1 1)' )
assert( u(s(p'(+ (+ a a) a)', p'1', p'a'))
	== '(+ (+ 1 1) 1)')
assert( u(s(p'(+ a ...)', p'(1 2)', p'...'))
	== '(+ a 1 2)')
		

function variable(t)
	return atom(t) and t:upper()==t and t:lower()~=t:upper()
end

-- (a b), (A b) -> {A=a}
function match(sexp, src, res)
	res = res or {}

	if atom(src) and variable(src) then
		-- mismatch
		if res[src] and hash(res[src])~=hash(sexp) then
			return false
		end
		res[src] = sexp

	-- ... -> ALLES
	elseif atom(src) and string.sub(src, -3) == '...' then
		res[src] = sexp

	-- tau -> tau
	elseif atom(src) and src == sexp then
		return res

	elseif atom(src) and src ~= sexp then
		return false

	-- (A B) -> (a b)
	-- (A ...) -> (a b c)
	else
		-- obtain info
		local n
		local var
		if atom(src[#src]) and string.sub(src[#src], -3) == '...' then
			var = src[#src]
		end
		if var then
			n = #src - 1
			if #sexp < n then
				return false
			end
		else
			n = #src
			if #sexp ~= n then
				return false
			end
		end

		-- recurseer
		for i=1,n do
			res = match(sexp[i], src[i], res)
			if not res then
				return false
			end
		end

		-- ellips
		if var then 
			local ellips = {}
			for i=n+1,#sexp do
				table.insert(ellips, sexp[i])
			end
			res[var] = ellips
		end
	end
	return res
end

local p = parseInfix
assert(match(p'0+a', p'0+A').A == 'a')
assert(match(p'a+a', p'A+A').A == 'a')
assert(not match(p'a+b', p'A+A'))
assert(match(p'1,2,3 + a', p'A,B + C'))
assert(match(p'a*2 = 4 <=> a = 4/2', p'A*B = C <=> A = C/B'))

function apply(sexp, rule)
	local src = copy(rule[2])
	local dst = copy(rule[3])
	local fixes = match(sexp,src)
	if fixes then
		-- rint('src = ',unparse(src))
		-- rint('dst = ',unparse(dst))
		local alt = dst
		for name,val in pairs(fixes) do
			-- rint(name .. " = " .. unparse(val))
			alt = substitute(alt, val, name)
		end
		return alt
	end
end

-- (a:=3 b:=a+a) oplosser
function evalLabel(sexp)
	if atom(sexp) then
		return
	end

	-- substitute
	for _,eq in ipairs(sexp) do
		local src,dst = eq[2],eq[3]

		-- enkele variabele
		if atom(src) then
			for i,eq in ipairs(sexp) do
				eq[3] = substitute(eq[3], dst, src)
			end
		else
			eq[3] = 'error'
		end
	end
	
	-- evaluate
	for _,eq in ipairs(sexp) do
		if eq[1]~='=' then
			eq[3] = evalPure(eq[3])
		end
	end
	
	return sexp
end
	
local arith = {
	['+'] = function (a,b) return a + b end;
	['-'] = function (a,b) if not b then return -a else return a - b end end;
	['*'] = function (a,b) return a * b end;
	['/'] = function (a,b) return b~=0 and a / b or 'oo' end;
	['^'] = function (a,b) return a ^ b end;
	['_'] = function (a,b) return math.log(a) / math.log(b) end;

	['>'] = function (a,b) return a > b end;
	['<'] = function (a,b) return a < b end;
	['>='] = function (a,b) return a >= b end;
	['<='] = function (a,b) return a <= b end;
}

local rulesource = parse(file('rules.sas'))

-- (and (and A B) C)
-- (and A B)
local rules = {}
local cur = rulesource
local rule = cur[3]

while rule do
	if rule[1] == '=' or rule[1] == '<=>' then
		insert(rules, {rule[1],rule[2],rule[3]})
		insert(rules, {rule[1],rule[3],rule[2]})
	elseif rule[1] == '=>' then
		insert(rules, {'=>',rule[2],rule[3]})
		insert(rules, {'<=',rule[3],rule[2]})
	elseif rule[1] == '<=' then
		insert(rules, {'=>',rule[3],rule[2]})
		insert(rules, {'<=',rule[2],rule[3]})
	end
	print(unparse(rule))
	cur = cur[2]
	rule = cur[3]
end

function evalSubst(sexp)
	for i,rule in ipairs(rules) do
		if rule[1]=='=>' then
			local res = apply(sexp, rule)
			if res then
				print('subst', unparse(rule))
				return res
			end
		end
	end
end

function evalNum(sexp)
	if exp(sexp) then
		local a,b = tonumber(sexp[2]),tonumber(sexp[3])
		local op = arith[sexp[1]]
		if op and a and b then
			local c = op(a,b)

			if tonumber(tostring(c)) then

				-- (+ a b)
				if #sexp == 3 then
					return tostring(c)
				end

				-- (+ a b ...)
				local res = {sexp[1], tostring(c)}
				for i=4,#sexp do
					table.insert(res, sexp[i])
				end
				return res
			end
		end
	end
end

function evalRec(sexp)
	if exp(sexp) then
		-- recurseer
		for i,v in ipairs(sexp) do
			local s = evalRec(v)
			if s then
				sexp[i] = s
				--return sexp -- ?
			end
		end

		-- subsystemen
		local res
		res = evalNum(res or sexp) or res
		res = evalSubst(res or sexp) or res
		return res
	end
end

-- onveilig! verandert sexp
-- GOED
function quantumKids(sexp, cache, i)
	i = i or 1
	if not sexp[i] then
		return
	end

	local all = coroutine.wrap(quantum, sexp[i], cache)
	for alt in all do
		sexp[i] = alt
		if i < #sexp then
			quantumKids(sexp, cache, i+1)
		else
			quantum(copy(sexp), cache)
		end
	end
end

function quantum(sexp, cache)
	cache = cache or {}

	-- bescherm onszelf
	local self = hash(sexp)
	if not cache[self] then
		coroutine.yield(sexp)
		cache[self] = sexp
	else
		return
	end

	-- we verzinnen onze eigen regels
	for i,rule in ipairs(rules) do
		if rule[1]=='=' then
			local alt = apply(sexp, rule)
			if alt then
				local h = hash(alt)
				if not cache[h] then
					coroutine.yield(alt)
					-- gewoon lekker doorgaan - de cache beschermt ons
					quantum(alt, cache)
					cache[h] = alt
				end
			end
		end
	end

	-- schandalig onszelf tentoonstellen zit hierbij
	-- onzere kinderen mogen nu
	quantumKids(sexp, cache)
end

function coroutine.wrap(func, ...)
	local coro = coroutine.create(func)
	local tt = {...}
	return function()
		local ok,msg = coroutine.resume(coro, table.unpack(tt))
		if ok then
			return msg
		else
			error(msg)
		end
	end
end

function perms(sexp)
	local res = {}
	for i,rule in pairs(rules) do
		local a = apply(sexp, rule)
		if a then
			table.insert(res, a)
		end
	end
	return res
end

function eval2(sexp)
	while true do
		local better

		-- generate alternatives
		local all = coroutine.wrap(quantum, sexp)
		for alt in all do
			better = evalRec(alt)
			if better then
				break
			end
		end

		if not better then
			break
		end

		sexp = better
		print('!',better)
	end

	return sexp
end

local function findAlternatives(sexp)
	local alts = {sexp}
	local done = {}
	local todo = {sexp}

	while #todo > 0 do
		local sexp = remove(todo)

		-- alternatieven
		for i,rule in ipairs(rules) do
			if rule[1] == '<=>' or rule[1] == '=' then
				local alt = apply(sexp, rule)
				if alt then
					local key = unparseSexpCompact(alt)
					if not done[key] then
						insert(alts,alt)
						insert(todo,alt)
						done[key] = true
					end
				end
			end
		end
	end
		
	-- alternatieven voor kinderen van alternatieven

	return alts
end

function evalCalc(sexp)
	local op = sexp[1]
	local a = tonumber(sexp[2])
	local b = tonumber(sexp[3])
	if arith[op] and a and b then
		local c = arith[op](a,b)
		return tostring(c)
	end
	return nil
end

function eval(sexp)
	local alts = findAlternatives(sexp)
	local best = sexp
	local better = best
	local ok = false

	while better do
		best = better
		better = false
		alts = findAlternatives(best)
		print(#alts, unparse(best))

		for i,sexp in ipairs(alts) do
			-- recursive pass
			if exp(sexp) then
				local ok
				for i,v in ipairs(sexp) do
					if exp(v) then
						sexp[i], ok = eval(v)
					end
				end
				if ok then
					better = sexp
					break
				end
			end

			better = evalSubst(sexp)
			better = evalCalc(better or sexp) or better
			if better then
				ok = true
				break
			end
		end
	end

	return best, ok
end

local function unique(sexp)
	local assoc = {
		['='] = true, ['|'] = true, ['<=>'] = true, ['and'] = true,
		['+'] = true,
	}
	if exp(sexp) and assoc[sexp[1]] then
		local op = sexp[1]
		local s2,s3 = unique(sexp[2]), unique(sexp[3])
		local a, b
		if s2 > s3 then
			a,b = s2,s3
		else
			a,b = s3,s2
		end
		sexp = {op,a,b}
	elseif exp(sexp) then
		sexp = {op,unique(sexp[2]),unique(sexp[3])}
	end
	return unparseSexpCompact(sexp)
end

local function equals(a,b)
	local a = unique(a)
	local b = unique(b)
	return a == b
end

assert(unique(p'b + a') == unique(p'a + b'))
assert(unique(p'a + c + b') == unique(p'c + a + b'))
assert(unique(p'a + b = b + a') == unique(p'b + a = a + b'))
assert(equals(p'(a+1),(b+2)', p'(1+a),(2+b)'))


require 'sas'

function test(q,a)
	local l = eval(parse(q))
	local a = parse(a)
	assert(equals(l,a), 'verwachtte '..unparse(a)..', was '..unparse(l))
end

test('a*2 = 4', 'a = 2')
do return end

-- abc acb bac bca cab cba
--assert(#alts(parse('a + b + c')) == 6)
assert(#alts(parse('a + b')) == 2)
test('1 + 2', '3')
test('a + a', '2 * a')
test('a * a', 'a ^ 2')
test('a = a', 'true')
test('a,b = 1,2', 'a = 1 and b = 2')
test('a,b,c = 1,2,3', 'a = 1 and b = 2 and c = 3')
test('a + 1,2,3', '(a+1),(a+2),(a+3)')
test('a*2 = 4', 'a = 2')
