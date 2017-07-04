require 'pure'

function substitute(sexp, dst, src)
	if atom(sexp) then
		if sexp==src then
			return dst
		else
			return sexp
		end
	else
		local res = {}
		for i=1,#sexp do
			res[i] = substitute(sexp[i], dst, src)
		end
		return res
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
	
function evalTest(sexp)
	local res = sexp
	if exp(sexp) and sexp[1]=='=?' then
		if #sexp == 3 then
			local a = sexp[2]
			local b = sexp[3]
			local a = unparse(a)
			local b = unparse(b)
			if a==b then
				return 'true'
			else
				return sexp
			end
		else
			return 'syntax-error'
		end
	end
	return res
end

local numFunctions = {
	['+'] = function (a,b) return a + b end;
	['-'] = function (a,b) return a - b end;
	['*'] = function (a,b) return a * b end;
	['/'] = function (a,b) return b~=0 and a / b or 'oo' end;
	['^'] = function (a,b) return a ^ b end;
}


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
				return 'syntax-error'
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
		if #args==1 then
			return tostring(args[1])
		end

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
		for i,v in pairs(sexp) do
			sexp[i] = evalRec(v)
		end

		-- subsystemen
		sexp = evalNum(sexp)
		sexp = evalTest(sexp)
	end
	return sexp
end

function eval(sexp)
	local prev = unparse_small(sexp)
	while true do
		sexp = evalRec(sexp)

		local now = unparse_small(sexp)
		if now == prev then
			break
		end
		prev = now
	end
	return sexp
end
