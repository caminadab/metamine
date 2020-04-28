
local altijdja = X('_fn', '12358', '⊤')

local function fnaam(exp)
	return (fn(exp) == '_' or fn(exp) == '_f') and atoom(arg0(exp))
end

local function sourcelen(exp)
	if fn(exp) == '..' then
		return X('+', arg1(exp), X('-', arg0(exp)))
	end
	if fn(exp) == '+v1' or fn(exp) == '·v1' then
		--print('++', unlisp(sourcelen(arg0(exp))))
		return sourcelen(arg0(exp))
	end
	if fnaam(exp) == 'map' then
		return sourcelen(arg1(exp)[1])
	end
	if fnaam(exp) == 'filter' then
		return sourcelen(arg1(exp)[1])
	end
	if fnaam(exp) == 'zip' then
		return sourcelen(arg1(exp)[1])
	end
	if isobj(exp) then
		return X(tostring(#exp))
	end
	if fn(exp) == '×' then
		--return X('·', sourcelen(arg0(exp)), sourcelen(arg1(exp)))
		local x = sourcelen(arg0(exp))
		local y = sourcelen(arg1(exp))
		if obj(x) == '[]' then
			x[#x+1] = y
			return x
		end
		return X('[]', x, y)
	end
	--error('onbekende lengte van '..combineer(exp))
	return nil
end

local function sourcefilter(exp)
	if fnaam(exp) == 'filter' then
		return arg1(exp)[2]
	end
	if fnaam(exp) == 'map' then
		return sourcefilter(arg1(exp)[1])
	end
	return altijdja
end

-- genereer un source
local function sourcegen(exp)
	if fn(exp) == '..' then
		if atoom(arg0(exp)) == '0' then
			return X'fn.id'
		end
		return X('_f', 'fn.plus', arg0(exp))
	end
	if fn(exp) == '+v1' then
		local get = arg0(exp)
		local add = X('_f', 'fn.plus', arg1(exp))
		return X('∘', get, add)
	end
	if fn(exp) == '·v1' then
		local get = arg0(exp)
		local mul = X('_f', 'fn.mul', arg1(exp))
		return X('∘', get, mul)
	end
	if fnaam(exp) == 'map' then
		local a = arg1(exp)[1]
		local f = arg1(exp)[2]
		return X('∘', sourcegen(a), f)
	end
	if fnaam(exp) == 'zip' then
		local a, b = arg1(exp)[1], arg1(exp)[2]
		local arg = X(',', sourcegen(a), sourcegen(b))
		return X('_f', 'fn.merge', arg)
	end
	if isobj(exp) then
		-- i → y[i]
		return X('_fn', '777', X('_l', exp, X('_arg', '777')))
	end
	if fn(exp) == '×' then
		if fn(arg0(exp)) == '×' then
			local a = X('∘', 'l.eerste', sourcegen(arg0(arg0(exp))))
			local b = X('∘', 'l.tweede', sourcegen(arg1(arg0(exp))))
			local c = X('∘', 'l.derde', sourcegen(arg1(exp)))
			return X('_f', 'fn.merge', X(',', a, b, c))
		else
			local a = X('∘', 'l.eerste', sourcegen(arg0(exp)))
			local b = X('∘', 'l.tweede', sourcegen(arg1(exp)))
			return X('_f', 'fn.merge', X(',', a, b))
		end

	end
	--error(unlisp(exp))
	return X'fn.id'
end

function optimiseer(exp, issub)
	--do return exp end
	if fn(exp) == '_l' and atoom(arg1(exp)) == '0' then
		assign(exp, X('_l0', arg0(exp)))
	end

	if fn(exp) == 'Σ' then
		local nexp = X('_f', 'vouw', X(',', arg(exp), '+'))
		return optimiseer(nexp, true)
	end

	if fnaam(exp) == 'map' then
		local lijst = arg1(exp)[1]
		local func  = arg1(exp)[2]
		local gen = sourcegen(lijst)
		local map = X('∘', gen, func)
		local max = sourcelen(lijst)
		local filter1 = sourcefilter(lijst)
		local filter2 = altijdja

		if not max or not gen then
			return exp
		end

		local nexp = X('_f', 'lvoor', X(',', max, filter1, map, filter2))
		if true then
			print('lvoor')
			print('max', combineer(max))
			print('filter1', combineer(filter1))
			print('map', combineer(map))
			print('filter2', combineer(filter2))
		end
		return nexp
	end

	if fnaam(exp) == 'vouw' then
		local lijst = arg1(exp)[1]
		local vouw  = arg1(exp)[2]
		local map = sourcegen(lijst)
		local max = sourcelen(lijst)
		local filter1 = sourcefilter(lijst)
		local filter2 = X'fn.id'

		if not max or not map then
			return exp
		end


		local start
		if isobj(max) then
			local zeros = {o=X','}
			for i=1,#max do
				zeros[i] = X'0'
			end
			start = X('_f', map, zeros)
		else
			start = X('_f', map, '0')
		end

		if isobj(max) then
		elseif #max == 2 then
			start = X('_l', map, X(',', '0', '0'))
		elseif #max == 3 then
		elseif #max == 4 then
		elseif #max == 5 then
		else
			start = X'0' --('_f', map, '0')
		end

		local nexp = X('_f', 'voor', X(',', max, start, filter1, map, filter2, vouw))
		if true then
			print('voor')
			print('max', combineer(max))
			print('filter1', combineer(filter1))
			print('filter2', combineer(filter2))
			print('map', combineer(map))
			print('vouw', combineer(vouw))
		end
		return nexp
	end

	-- optimiseer subs
	local nexp = {}
	for k, sub in subs(exp) do
		nexp[k] = optimiseer(sub,true)
	end
	for k,v in pairs(nexp) do
		exp[k] = v
	end


	return exp
end
