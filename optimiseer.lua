require 'symbool'

local altijdja = X('_fn', '12358', '⊤')

local function fnaam(exp)
	return (fn(exp) == '_' or fn(exp) == '_f' or fn(exp) == '_f2') and atoom(arg0(exp))
end

function devec(exp)
	if fnaam(exp) == 'map2' then
		local lijst = arg1(exp)
		local func  = arg2(exp)

		local delijst = devec(lijst)
		if delijst then
			--return X('imap', delijst, func)
		end
		--return X'ok'

	elseif false and fnaam(exp) == 'filter2' then
		local lijst = arg1(exp)
		local func  = arg2(exp)
		local delijst = devec(lijst)
		if delijst then
			return X('ifilter', delijst, func)
		end
	elseif fn(exp) == '..' then
		if atoom(arg0(exp)) == '0' then
			return X('igen', arg1(exp))
		else
			return X('igeni', arg2(exp), arg1(exp))
		end
	end
end

-- (+), id 

-- optimiseer compositie
function compopt(exp, maakindex)
	local a = arg0(exp)
	local b = arg1(exp)
	if fn(a) == '_fn' and fn(b) == '_fn' then
		local abody = arg1(a)
		local bbody = arg1(b)
		local aarg = atoom(arg0(a))
		local barg = atoom(arg0(b))
		local cindex = tostring(maakindex())
		local carg = X('_arg', cindex)
		
		local nbody = kloon(bbody)
		local aabody = kloon(abody)
		local aabody = substitueer(aabody, X('_arg', aarg), carg)
		local cbody = substitueer(nbody, X('_arg', barg), aabody)
		local c = X('_fn', cindex, cbody)
		--print(combineer(abody))
		--print(combineer(bbody))
		--print(combineer(c))

		return c

	-- (-) ∘ (-) = (x → -(-(x)))
	elseif isatoom(a) and isatoom(b) then
		local index = tostring(maakindex())
		local anaam = atoom(a)
		local bnaam = atoom(b)

		local arg = X('_arg', index)
		local c
		if unop[anaam] then
			c = X(anaam, arg)
		else
			c = X('_f', anaam, arg)
		end
		local d
		if unop[bnaam] then
			d = X(bnaam, c)
		else
			d = X('_f', bnaam, c)
		end

		return X('_fn', index, d)

	-- (x → x + 1) ∘ (-) = (x → -(x + 1))
	elseif fn(a) == '_fn' and isatoom(b) then
		local aarg  = atoom(arg0(a))
		local abody = arg1(a)
		local bnaam = atoom(b)
		local cbody = kloon(abody)

		local c
		if unop[bnaam] then
			c = X('_fn', aarg, X(bnaam, cbody))
		else
			c = X('_fn', aarg, X('_f', bnaam, cbody))
		end

		return c
	end
end

-- lus: gen,map,col
function optimiseer(exp)
	local maakindex = maakindices(1000)
	for exp in boompairsdfs(exp) do
		if fn(exp) == '∘' then
			local nexp = compopt(exp, maakindex)
			if nexp then
				--error(combineer(nexp))
				assign(exp, nexp)
			end
		end
	end
do return exp end
	for exp in boompairsbfs(exp) do
		if fn(exp) == 'Σ' then
			local lijst = arg(exp)
			local start = X'0'
			local gen = devec(lijst)
			local col = X'+'

			if gen then
				local nexp = X('lus', start, gen, col)
				assign(exp, nexp)
			end

		elseif fnaam(exp) == 'map2' or fnaam(exp) == 'filter2' then
			local lijst = arg1(exp)
			local func = arg2(exp)

			local gen = devec(lijst)
			local start = {o=X'[]'}
			local col = X('∘', func, X'append')

			if gen then
				local nexp = X('lus', start, gen, col)
				assign(exp, nexp)
			end
		end
	end
	return exp
end

				

