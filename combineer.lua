require 'lisp'
require 'func'
require 'set'

local insert = table.insert

local binop = set('+', '-', '*', '/', '^', 'en', 'of', '@', '=>')
local lop = set('=', '!=', '=>', '>', '<', '>=', '<=')

local function combineerR(exp, tt)
	if isatoom(exp) then
		insert(tt, exp.v)

	-- tekst
	elseif exp.o == '[]u' then
		local tekst = string.char(table.unpack(map(exp, function(x) return x.v end)))
		insert(tt, string.format('%q', tekst))

	elseif isobj(exp) then
		local op = exp.f.v
		if op == ',' then op = '()' end
		insert(tt, op:sub(1,1))
		for i=1,#exp.a do
			combineerR(exp[i], tt)
			if i ~= #exp then
				insert(tt, ', ')
			end
		end
		insert(tt, op:sub(2,2))

	else
		if not exp.f then
			see(exp)
			print(type(exp))
			for k,v in pairs(exp) do print(k,v) end
			error'GEEN FN'
		end
		local op = exp.f.v

		-- navoegsel
		if op == '%' or op == "'" then
			combineerR(exp.a, tt)
			insert(tt, op)

		-- unop
		elseif exp.a then
			if op then
				insert(tt, op)
			else
				-- complexe functie
				insert(tt, '(')
				combineerR(exp.f, tt)
				insert(tt, ')')
			end

			if isatoom(exp[1]) then
				insert(tt, ' ')
				insert(tt, exp[1].v)
			else
				insert(tt, ' (')
				combineerR(exp[1], tt)
				insert(tt, ')')
			end

		-- binop
		elseif #exp == 2 then
			for i=1,#exp do
				local v = exp[i]
if not v.f and not v.v then see(v); error('geen exp: '..e2s(v)) end
				local br = isfn(v) and binop[v[1]] and binop[op] and binop[v[1]] <= binop[op]
				local br = br or (isfn(exp.f) and (lop[fn(exp.f)]))-- or (#v == 2 and not binop[fn(exp[i])]))


				if br then insert(tt, '(') end

				combineerR(exp[i], tt)

				if br then insert(tt, ')') end

				if i ~= #sexp then
					insert(tt, ' ')
					if op then
						insert(tt, op)
					else
						-- complexe functie
						insert(tt, '(')
						combineerR(sexp.f, tt)
						insert(tt, ')')
					end
					insert(tt, ' ')
				end

			end

		-- n-air
		else
			if binop[op] then insert(tt, '(') end
			insert(tt, op)
			if binop[op] then insert(tt, ')') end
			insert(tt, '(')

			for i=1,#sexp do
				combineerR(sexp[i], tt)
				if i~=#sexp then insert(tt, ', ') end
			end
			insert(tt, ')')
		end
	end

	-- plet
	for i,v in ipairs(tt) do
		if isfn(v) then
			tt[i] = unlisp(tt[i])
		end
	end
	return tt
end

function combineer(sexp)
	if not sexp then
		return '<niets>'
		--error('ongeldige s-exp')
	end

	local tt = combineerR(sexp, {})
	return table.concat(tt)
end

combineer = e2s
