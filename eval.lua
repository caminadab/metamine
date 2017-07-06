require 'pure'

function substitute(sexp, dst, src)
	if atom(sexp) then
		if sexp==src then
			return dst
		else
			return sexp
		end
	else
		for i=1,#sexp do
			if src=='...' and sexp[i]=='...' then
				for j=1,#dst do
					table.insert(sexp, i+j, dst[j])
				end
				table.remove(sexp, i)
			else
				sexp[i] = substitute(sexp[i], dst, src)
			end
		end
		return sexp
	end
end

function variable(t)
	return atom(t) and t:upper()==t and t:lower()~=t:upper()
end

-- (a b), (A b) -> {A=a}
function match(sexp, src, res)
	res = res or {}
	if not src then print(debug.traceback()); error('no source provided') end

	if src[#src] == '...' then
		if #sexp < #src - 1 then
			return false
		end
	else
		if #sexp ~= #src then
			return false
		end
	end

	-- last
	local len = #sexp
	if src[#src] == '...' then
		local tail = {}
		for i=#src,#sexp do
			table.insert(tail, sexp[i])
		end
		res['...'] = tail
		len = #src - 1
	end

	for i=1,len do
		if src[i]=='...' then
			-- negeren maar
		elseif variable(src[i]) then
				-- val mismatch
				if res[src[i]] and unparse_small(sexp[i]) ~= unparse_small(res[src[i]]) then
					return false
				end

				-- het klopt
				res[src[i]] = sexp[i]

		-- expressie/atoom misfit
		elseif atom(src[i]) ~= atom(sexp[i]) then
				-- gaat niet
				return false

		-- goed
		elseif atom(src[i]) then
			if src[i] ~= sexp[i] then
				return false
			end

		-- genest
		else
			res = match(sexp[i], src[i], res)
			if not res then
				return false
			end
		end
	end
	return res
end

assert(match(parse("(+ 0 a)"), parse("(+ 0 A)")).A == 'a')
assert(match(parse("(+ a a)"), parse("(+ A A)")).A == 'a')
assert(match(parse("(+ 1 1 b)"), parse("(+ A A ...)")).A == '1')
assert(match(parse("(| 1 1 2 0)"), parse("(| A A ...)")).A == '1')
assert(match(parse("(+ a)"), parse("(+ 0)")) == false)
assert(match(parse("(+ a)"), parse("(+ A B)")) == false)
assert(match(parse("(+ a)"), parse("(+ A B)")) == false)
assert(unparse(match(parse("(+ a)"), parse("(+ ...)"))['...']) == '(a)')
assert(unparse(match(parse("(+ a b)"), parse("(+ A ...)"))['...']) == '(b)')
assert(unparse(match(parse("(+ a b)"), parse("(+ A ...)"))['...']) == '(b)')
assert(unparse(match(parse("(+)"), parse("(+ ... )"))['...']) == '()')


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
	
function evalTest(sexp)
	local res = sexp
	if exp(sexp) and sexp[1]=='=?' then
		if #sexp == 3 then
			local a = sexp[2]
			local b = sexp[3]
			local a = unparse_small(a)
			local b = unparse_small(b)
			if a==b then
				return 'true'
			else
				return sexp
			end
		else
			return 'test-syntax-error'
		end
	end
	return res
end

local numFunctions = {
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
				return res
			end
		end
	end
	return sexp
end


-- (+ 1 2) of (+ (1 2))
function evalNum(sexp)
	local args = {}
	if exp(sexp) then
		local op = sexp[1]

		-- irrelevante formule
		if not numFunctions[op] then
			return sexp
		end

		-- (+ 1 2)
		if atom(sexp[2]) then
			for i=2,#sexp do
				local num = tonumber(sexp[i])
				if not num then
					return sexp
				end
				args[i-1] = num
			end
		else
			if #sexp ~= 2 then
				return sexp
			end
			for i=1,#sexp[2] do
				local num = tonumber(sexp[2][i])
				if not num then
					return sexp
				end
				args[i] = num
			end
		end

		-- hoe definieer je + 1? als 1 toch?
		if #args==0 then return 'syntax-error' end

		-- a-b-c

		local fn = numFunctions[op]
		if fn then
			local res = fn(args[1], args[2])
			for i=3,#args do
				res = fn(res, args[i])
			end
			return tostring(res)
		end
	else
		return sexp
	end
end

function evalRec(sexp)
	if exp(sexp) then
		-- recurseer
		for i,v in ipairs(sexp) do
			sexp[i] = evalRec(v)
		end

		-- subsystemen
		sexp = evalNum(sexp)
		sexp = evalTest(sexp)
		sexp = evalSubst(sexp)
	end
	return sexp
end

function apply(sexp, rule)
	local src = copy(rule[2])
	local dst = copy(rule[3])
	local fixes = match(sexp,src)
	if fixes then
		-- print('src = ',unparse(src))
		-- print('dst = ',unparse(dst))
		local alt = dst
		for name,val in pairs(fixes) do
			-- print(name .. " = " .. unparse(val))
			alt = substitute(alt, val, name)
		end
		return alt
	end
end

-- onveilig! verandert sexp
function quantumKids(sexp, cache, i)
	i = i or 1

	local all = coroutine.wrap(quantum, sexp[i])
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
	local self = unparse_small(sexp)
	if not cache[self] then
		coroutine.yield(sexp)
		cache[self] = sexp
	else
		return
	end

	-- we verzinnen onze eigen regels
	for i,rule in pairs(rules) do
		if rule[1]=='=' then
			local alt = apply(sexp, rule)
			if alt then
				local lisp = unparse_small(alt)
				if not cache[lisp] then
					coroutine.yield(alt)
					-- gewoon lekker doorgaan - de cache beschermt ons
					quantum(alt, cache)
					cache[lisp] = alt
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


function evalQuantum(sexp)
	local all = coroutine.wrap(quantum, sexp)
	for alt in all do
		io.write(unparse(alt), '\t')
		local a = evalRec(alt)
		if unparse_small(a) ~= unparse_small(alt) then
			return a
		end
	end
	return sexp
end

function eval(sexp)
	print('eval', unparse(sexp))
	local prev = unparse_small(sexp)
	while true do
		sexp = evalQuantum(sexp)

		local now = unparse_small(sexp)
		if now == prev then
			break
		end
		prev = now
	end
	return sexp
end
