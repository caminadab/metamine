require 'pure'

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

local s,p,u = substitute,parse,unparse
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

local p = parse
assert(match(p'(+ 0 a)', p'(+ 0 A)').A == 'a')
assert(match(p'(+ a a)', p'(+ A A)').A == 'a')
assert(match(p'(+ 1 1 b)', p'(+ A A ...)').A == '1')
assert(match(p'(| 1 1 2 0)', p'(| A A ...)').A == '1')
assert(match(p'(+ a)', p'(+ 0)', true) == false)
assert(match(p'(+ a)', p'(+ A B)') == false)
assert(match(p'(+ a)', p'(+ A B)') == false)
assert(unparse(match(p'(+ a)', p'(+ ...)')['...']) == '(a)')
assert(unparse(match(p'(+ a b)', p'(+ A ...)')['...']) == '(b)')
assert(unparse(match(p'(+ a b)', p'(+ A ...)')['...']) == '(b)')
assert(unparse(match(p'(+)', p'(+ ... )')['...']) == '()')
assert(unparse(match(p'(+ (1 2 3))', p'(+ ...)')['...']) == '((1 2 3))')
assert(unparse(match(p'(+ a b)', p'(+ ...)')['...']) == '(a b)')
assert(not match(p'(+ 1 2 3)', p'(+ A A ...)'))


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
}

local rules = parse(file('rules.lisp'))

function evalSubst(sexp)
	for i,rule in ipairs(rules) do
		if rule[1]=='=>' then
			local res = apply(sexp, rule)
			if res then
				--rint('subst', rule)
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

function quantum2(sexp, cache)
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


function alts(sexp)
	-- atom has one possibility
	if atom(sexp) then
		return {sexp}
	end

	-- maak kruizen
	local cross = {}
	for i=1,#sexp do
		cross[i] = alts(sexp[i])
	end

	-- kruisproduct
	for 
end
	

function eval(sexp)
	return sexp
end
	
function eval2(sexp)
	while true do
		local better

		-- generate alternatives
		local all = coroutine.wrap(quantum, sexp)
		for alt in all do
			print('alt',alt)
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
