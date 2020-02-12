require 'exp'
require 'combineer'

local tel = { X'fn.eerste', X'fn.tweede', X'fn.derde', X'fn.vierde' }
local id = X'fn.id'
local dup = X'fn.dup'
local merge = X'fn.merge'
local constant = X'fn.constant'
local inc = X'fn.inc'
local dec = X'fn.dec'
local kruid = X'fn.kruid'
local kruidL = X'fn.kruidL'


-- (1 + A) → fn.plus(1) ∘ d(A)
local op2fn = {
	['+'] = X'fn.plus',
	['·'] = X'fn.maal', 
	['/'] = X'fn.deel',

	['∧'] = X'fn.en',
	['∨'] = X'fn.of',

	['>'] = X'fn.groterdan',
	['≥'] = X'fn.grotergelijk',
	['='] = X'fn.is',
	['≠'] = X'fn.isniet',
	['≤'] = X'fn.kleinergelijk',
	['<'] = X'fn.kleinerdan',
	['⇒'] = X'fn.dan',
}

local rop2fn = {
	['+'] = X'fn.plus',
	['·'] = X'fn.maal', 
	['/'] = X'fn.rdeel',

	['∧'] = X'fn.en',
	['∨'] = X'fn.of',

	['>'] = X'fn.kleinergelijk',
	['≥'] = X'fn.kleinerdan',
	['='] = X'fn.is',
	['≠'] = X'fn.isniet',
	['≤'] = X'fn.groterdan',
	['<'] = X'fn.grotergelijk',
	['⇒'] = X'fn.als',
}

-- defunctionaliseer (maak er een gebonden functie van)
function defunc(exp, argindex, klaar)
	--if not klaar then print('DEFUNC', argindex) end
	klaar = klaar or {}
	if klaar[exp] then return klaar[exp] end
	local res
	local num = isfn(exp) and arg1(exp) and isatoom(arg1(exp)) and tonumber(atoom(arg1(exp)))

	-- C(exp)
	if not bevat(exp, X'_arg') then
		res = X(constant, exp)

	-- fn.id
	elseif fn(exp) == '_arg' and atoom(arg(exp)) == argindex then
		res = id

	-- fn.eerste t/m fn.vierde
	elseif fn(exp) == '_' and num and num >= 0 and num < 4 and num % 1 == 0 then
		local sel = tel[num + 1]
		local A = defunc(arg0(exp), argindex, klaar)
		if atoom(A) == 'fn.id' then
			res = X(sel) 
		else
			res = X('∘', A, X(sel))
		end

	-- abs(A)  →  d(A) ∘ abs
	elseif fn(exp) == '_' then
		local d = defunc(arg1(exp), argindex, klaar)
		local achter = arg0(exp)

		if fn(d) == '∘' then
			res = kopieer(d)
			table.insert(arg(res), achter)
		else
			res = X('∘', d, achter)
		end


	-- fn.kruid
	-- A + 2  →  d(A) ∘ kruid((+), 2)
	elseif isfn(exp) and #arg(exp) == 2
			and not bevat(arg0(exp), X('_arg', argindex)) then
		local d = defunc(arg1(exp), argindex, klaar)
		local f = fn(exp)

		local achter
		if op2fn[f] then
			achter = X(op2fn[f], arg0(exp))
		else
			achter = X('fn.kruid', X(',', f, arg0(exp)))
		end

		-- samenvoegen van compositie
		if fn(d) == '∘' then
			res = kopieer(d)
			table.insert(arg(res), achter)
		else
			res = X('∘', d, achter)
		end

	-- fn.kruidL
	-- 2 + A  →  kruidL((+), 2) ∘ d(A)
	elseif isfn(exp) and #arg(exp) == 2
			and not bevat(arg1(exp), X('_arg', argindex)) then
		local d = defunc(arg0(exp), argindex, klaar)

		local achter
		local f = fn(exp)
		if rop2fn[f] then
			achter = X(op2fn[f], arg1(exp))
		else
			achter = X('fn.kruidL', X(',', fn(exp), arg1(exp)))
		end

		-- samenvoegen van compositie
		if fn(d) == '∘' then
			res = kopieer(d)
			table.insert(arg(res), achter)
		else
			res = X('∘', d, achter)
		end
	

	-- fn.inc
	elseif fn(exp) == '+' and isobj(arg(exp)) and #obj(arg(exp)) == 2
			and (arg0(exp).v == '1' or arg1(exp).v == '1') then
		if arg0(exp).v == '1' then
			res = X(inc, arg0(exp).v)
		else
			res = X(inc, arg1(exp).v)
		end

	-- f(a)  ->  c(a) ∘ f
	elseif isfn(exp) and fn(exp) ~= '_arg' then
		local A = defunc(arg(exp), argindex, klaar)
		if atoom(A) == 'fn.id' then
			res = fn(exp)
		else
			if fn(A) == '∘' then
				res = X('∘', arg0(A), arg1(A), fn(exp))
			else
				res = X('∘', A, fn(exp))
			end
		end

	-- merge
	elseif isobj(exp) then
		local mergeval = {o=exp.o}
		for k, sub in subs(exp) do
			mergeval[k] = defunc(sub, argindex, klaar)
		end

		-- special case: merge(id, id) = dup
		if atoom(mergeval[1]) == 'fn.id' and atoom(mergeval[2]) == 'fn.id' and not mergeval[3] then
			res = dup
		elseif #mergeval == 0 then
			res = X'∅'
		elseif #mergeval == 1 then
			res = X(merge, mergeval[1])
		else
			res = X(merge, mergeval)
		end

	else
		res = X(constant, exp)
	end

	assert(res)

	klaar[exp] = res
	return res
end
