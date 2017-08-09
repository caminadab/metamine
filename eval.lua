require 'pure'
require 'sexp'
require 'sas'
require 'ansi'
local insert = table.insert
local remove = table.remove

-- logging
local verbose = true
function log(...)
	local trace = debug.traceback()
	local _, count = string.gsub(trace, "eval", "")
	print(string.rep(' ',count/2)..(...))
end

function depth()
	local trace = debug.traceback()
	local _, count = string.gsub(trace, "eval", "")
	return count/2
end

-- read rules
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
	elseif rule[1] == '<=' then
		insert(rules, {'=>',rule[3],rule[2]})
	end
	cur = cur[2]
	rule = cur[3]
end

function substitute(exp, dst, src)
	if atom(exp) then
		if exp == src then
			return dst, true
		else
			return exp, false
		end
	elseif unparseSexpCompact(exp) == unparseSexpCompact(src) then
		return dst, true
	else
		local r = {}
		local sok,ok
		for i,v in pairs(exp) do
			r[i],sok = substitute(v, dst, src)
			if sok then ok = true end
		end
		return r, ok
	end
end


function variable(t)
	return atom(t) and t:upper()==t and t:lower()~=t:upper()
end

-- (a b), (A b) -> {A=a}
function match(sexp, src, res)
	if not sexp then error("TIEF OP") end
	res = res or {}

	if atom(src) and variable(src) then
		-- mismatch
		if res[src] and hash(res[src])~=hash(sexp) then
			return false
		end
		res[src] = sexp

	-- tau -> tau
	elseif atom(src) and src == sexp then
		return res

	-- "hoi" MATCHT NIET (A B)
	elseif atom(sexp) and not atom(src) then
		return false

	elseif atom(src) and src ~= sexp then
		return false

	-- (A B) -> (a b)
	else
		-- niet evenveel
		if #sexp ~= #src then
			return false 
		end

		-- recurseer
		for i=1,#sexp do
			res = match(sexp[i], src[i], res)
			if not res then
				return false
			end
		end
	end
	return res
end

local p = parseInfix
assert(match(p'0+a', p'0+A').A == 'a') assert(match(p'a+a', p'A+A').A == 'a')
assert(not match(p'a+b', p'A+A'))
assert(match(p'1,2,3 + a', p'A,B + C'))
assert(match(p'a*2 = 4 <=> a = 4/2', p'A*B = C <=> A = C/B'))
assert(match('pi', 'pi'))
assert(match(p'a = #b + c', p'A = B + C'))
assert(match(p'#a', p'#a'))

local s = substitute(parse'#a = b', '3', parse'#a')
assert(hash(s) == hash(parse'3 = b'), unparse(s))
assert(hash(substitute(p"b = 'hoi'[0 .. # b]", p'3', p'#b')) == hash(p"b = 'hoi'[0 .. 3]"))

function apply(sexp, rule)
	if not sexp then error("OPKANKEREN") end
	local src = copy(rule[2])
	local dst = copy(rule[3])
	local fixes = match(sexp,src)
	if fixes then
		local alt = dst
		for name,val in pairs(fixes) do
			alt = substitute(alt, val, name)
		end
		return alt
	end
end

local a = (unparse(apply(p'pi', p'pi => tau / 2')))-- == u(p'tau / 2'))
local b = (unparse(p'tau/2'))
assert(a == b, a, b)

-- (+ (+ (+ a b) c) d)
function all(sexp, op)
	local r = {}
	local h = sexp
	while exp(h) and h[1] == op do
		local a = h[3]
		h = h[2]
		insert(r,a)
	end
	insert(r, h)

	return r
end

function isnamed(a)
	if exp(a) and #a == 2 then
		return isnamed(a[2])
	else
		return name(a)
	end
end

function ispure(a)
	return not istext(a) or isnumber(a)
end

function contains(sexp, a)
	if atom(sexp) then
		return sexp == a
	else
		for i,v in ipairs(sexp) do
			if contains(v, a) then
				return true
			end
		end
		return false
	end
end

-- a = b
function evalNames(sexp)
	-- verkrijg vergelijkingen
	local names = {}
	local eqs = all(sexp, 'and')
	if not eqs or #eqs < 2 then return end
	local ok

	-- bouw naam tabel
	for i,eq in ipairs(eqs) do
		if eq[1] == '=' then
			for p=1,2 do
				local a,b
				if p == 1 then
					a,b = eq[2],eq[3]
				else
					a,b = eq[3],eq[2]
				end

				if isnamed(a) and not contains(b, a) then
					-- vervang
					for j,eq in ipairs(eqs) do
						if i ~= j then
							eqs[j],sok = substitute(eq, b, a)
							if sok then ok = true end
							if ok then
								log('name: '..unparse(a)..' => '..unparse(b))
							end
						end
					end
					-- overbodig weghalen
					if name(a) and ok and not contains(eq, a) then
						remove(eqs,i)
					end
				end
			end
		end
	end

	-- bouw nieuwe vergelijkingen
	if ok then
		local h
		for i,val in ipairs(eqs) do
			local eq = {'=',val[2],val[3]}

			-- kleine sanitatie
			if not name(val[2]) and name(val[3]) then
				eq[2],eq[3] = eq[3],eq[2]
			end

			if not h then
				h = eq
			else
				h = {'and', h, eq}
			end
		end
		log('names: '..unparse(h))
		return h
	end
end
-- alle "=" en "and" regels zijn overbodig!
for i=#rules,1,-1 do
	if unparse(rules[i]) == 'A and B = B and A' then
		remove(rules, i)
	elseif unparse(rules[i]) == 'A = B <=> B = A' then
		remove(rules, i)
	end
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
	['=<'] = function (a,b) return a <= b end;
	['='] = function (a,b) return a == b end;
	['%'] = function (a,b) return a % b end;
}


function evalSubst(sexp)
	for i,rule in ipairs(rules) do
		if rule[1]=='=>' then
			local res = apply(sexp, rule)
			if res then
				log('subst: '..unparse(sexp)..' => '..unparse(res))
				return res
			end
		end
	end
end

local function findAlternatives(sexp)
	if atom(sexp) then
		return {sexp}
	end

	if not sexp then error("KANKER") end
	local basic = {sexp, [unparse(sexp)] = true}

	for it=1,2 do
		-- tweede golf
		for i,rule in ipairs(rules) do
			for i,b in ipairs(basic) do
				local alt = apply(b, rule)
				if alt and not basic[unparse(alt)] then
					insert(basic, alt)
					basic[unparse(alt)] = true
				end
			end
		end
	end

	if not exp(sexp) then
		return basic
	end

	-- creeer alle mogelijkheden
	local cart = {}
	local alts = {}
	for i=1,#basic do
		local sexp = basic[i]
		for j=1,#sexp do
			if sexp[j] == nil then error('waarom zelfs '..#sexp..', '..j..', '..unparseSexp(sexp)) end
			cart[j] = {sexp[j]}
			if exp(sexp[j]) then
				for k,rule in ipairs(rules) do
					if rule[1] == '<=>' or rule[1] == '=' then
						local alt = apply(sexp[j], rule)
						if alt and not cart[j][unparse(alt)] then
							insert(cart[j], alt)
							cart[j][unparse(alt)] = true
						end
					end
				end
			end
		end
		local total = 1
		for j=1,#sexp do
			if exp(cart[j]) then
				total = total * #cart[j]
			end
		end
		for j=1,total do
			local crafted = {}
			for k=1,#sexp do
				local l = j % #cart[k]
				j = math.floor(j / #cart[k])
				crafted[k] = cart[k][l+1]
			end
			insert(alts, crafted)
		end
	end

	return alts
end

print('asdfasdfasdf',unparseSexp(findAlternatives(parse('a + b + c'))))
assert(#findAlternatives(parse('a + b + c')) == 6)

function evalCalc(sexp)
	local op = sexp[1]
	local a = tonumber(sexp[2])
	local b = tonumber(sexp[3])
	local c

	if arith[op] and a and b then
		c = arith[op](a,b)
	
	-- unair
	elseif a and not sexp[3] then
		if op == '-' then
			c = -a
		elseif op == '+' then
			c = a
		elseif op == '_' then
			c = math.log(a)
		elseif op == '^' then
			c = math.exp(a)
		elseif math[op] then
			c = math[op](a,b)
		end

	-- getallen met basis
	elseif atom(sexp) and string.match(sexp, '%d+b') then
		c = tonumber(sexp:sub(1,-2), 2)
	elseif atom(sexp) and string.match(sexp, '%d+q') then
		c = tonumber(sexp:sub(1,-2), 4)
	elseif atom(sexp) and string.match(sexp, '%d.+h') then
		c = tonumber(sexp:sub(1,-2), 16)
	elseif atom(sexp) and string.match(sexp, '%d+d') then
		c = tonumber(sexp:sub(1,-2), 10)
	end
	
	if c then
		log('calc: '..unparse(sexp)..' => '..c)
		return tostring(c)
	end
end

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

function evalPure(sexp)
	local fn = sexp[1]
	local a = sexp[2]
	local b = sexp[3]
	local c

	-- bron s-exp
	if fn == 's-exp' then
		c = unparseSexp(a)

	-- concatenatie
	elseif fn == '||' then
		if istext(a) and istext(b) then
			c = totext(gettext(a)..gettext(b))
		end

	-- voorkauwen substring
	elseif istext(fn) and tonumber(a) then
		c = totext(fn:sub(a+2,a+2))
	elseif istext(fn) and exp(a) and a[1] == '..' then
		local b = tonumber(a[2])
		local e = tonumber(a[3])
		if b and e then
			c = totext(fn:sub(2+b,1+e))
		end

	-- reeks
	--[[
	elseif fn == '..' then
		local a = tonumber(a)
		local b = tonumber(b)
		if a and b then
			c = tostring(a)
			for i=a+1,b-1 do
				c = {',',c,tostring(i)}
			end
			print('is')
			print(unparse(c))
		end
	]]

	-- text lengte
	elseif fn == '#' and istext(a) then
		c = tostring(#a-2)

	-- conversions! vet
	elseif fn == '>>' then
		if isnumber(a) and b == 'text' then
			c = "'"..a.."'"
		end
	end

	if c then
		log('pure: '..unparse(sexp)..' => '..unparse(c))
	end

	return c
end

function eval(sexp, cache)
	if atom(sexp) then
		return sexp, false
	end
	cache = cache or {}
	if cache[unparseSexpCompact(sexp)] then
		return sexp, false
	end
	
	local hist = {}
	local alts
	local best = sexp
	local better = best
	local ok = false

	local it = 0

	while better and it < 80 do
		insert(hist, best)
		it = it + 1
		best = better
		better = false
		alts = findAlternatives(best)

		for i,sexp in ipairs(alts) do
			local cause = ''
			local d = depth()

			-- recursive pass
			if exp(sexp) then
				local rec = false
				local sexp = sexp
				for i,v in ipairs(sexp) do
					if exp(v) then
						local sok
						sexp[i], sok = eval(v, cache)
						if sok then
							rec = true
						end
					end
				end
				if rec then
					cause = cause .. ' recursion'
					better = sexp
				end
			end

			better = evalNames(better or sexp) or better		; if better then cause = cause .. ' names' end
			better = evalSubst(better or sexp) or better; if better then cause = cause .. ' subst' end
			better = evalPure(better or sexp) or better; if better then cause = cause .. ' pure' end
			better = evalCalc(better or sexp) or better; if better then cause = cause .. ' calc' end

			if better then
				best = better
				ok = true
				break
			else
				cache[unparseSexpCompact(sexp)] = true
			end
		end
	end

	--io.write(clearline)

	return best, ok, hist
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

local s = [[ a = 'hoi' and a = b || c and c = 'oi' ]]
--local s = [[ 'hoi' = b || 'oi' ]]
local s = [[ #b + 2 = 3 ]]
local r,ok,hist = eval(parse(s))
print("RESULTAAT: "..unparse(r))
print("LOG: ")
for i,h in ipairs(hist) do
	print(unparse(h))
end
do return end

-- abc acb bac bca cab cba
test('1 + 2', '3')
test('a + a', '2 * a')
test('a * a', 'a ^ 2')
test('a = a', 'true')
test('a,b = 1,2', 'a = 1 and b = 2')
test('a,b,c = 1,2,3', 'a = 1 and b = 2 and c = 3')
test('a + 1,2,3', '(a+1),(a+2),(a+3)')
test('a*2 = 4', 'a = 2')
test("'a' || 'b'", "'ab'")
--assert(#findAlternatives(parse('a + b')) == 2)
