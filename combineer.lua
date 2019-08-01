require 'lisp'
require 'func'
require 'set'

local insert = table.insert

local binop = set('+', '-', '*', '/', '^', 'en', 'of', '@', '=>')
local lop = set('=', '!=', '=>', '>', '<', '>=', '<=')

local function combineerR(sexp, tt)
	if isatoom(sexp) then
		insert(tt, sexp.v)
	else
		if not sexp.fn then
			see(sexp)
			print(type(sexp))
			for k,v in pairs(sexp) do print(k,v) end
			error'GEEN FN'
		end
		local op = sexp.fn.v

		-- lijst/set
		if op == '[]' or op == '{}' or op == ',' then
			if op == ',' then op = '()' end
			insert(tt, op:sub(1,1))
			for i=1,#sexp do
				combineerR(sexp[i], tt)
				if i ~= #sexp then
					insert(tt, ', ')
				end
			end
			insert(tt, op:sub(2,2))

		-- tekst
		elseif op == '[]u' then
			local tekst = string.char(table.unpack(map(sexp, function(x) return x.v end)))
			insert(tt, string.format('%q', tekst))

		-- navoegsel
		elseif op == '%' or op == "'" then
			combineerR(sexp[1], tt)
			insert(tt, op)

		-- unop
		elseif #sexp == 1 then
			if op then
				insert(tt, op)
			else
				-- complexe functie
				insert(tt, '(')
				combineerR(sexp.fn, tt)
				insert(tt, ')')
			end

			if isatoom(sexp[1]) then
				insert(tt, ' ')
				insert(tt, sexp[1].v)
			else
				insert(tt, ' (')
				combineerR(sexp[1], tt)
				insert(tt, ')')
			end

		-- binop
		elseif #sexp == 2 then
			for i=1,#sexp do
				local v = sexp[i]
if not v.fn and not v.v then see(v); error('geen exp: '..e2s(v)) end
				local br = isfn(v) and binop[v[1]] and binop[op] and binop[v[1]] <= binop[op]
				local br = br or (isfn(sexp.fn) and (lop[fn(sexp.fn)]))-- or (#v == 2 and not binop[fn(sexp[i])]))


				if br then insert(tt, '(') end

				combineerR(sexp[i], tt)

				if br then insert(tt, ')') end

				if i ~= #sexp then
					insert(tt, ' ')
					if op then
						insert(tt, op)
					else
						-- complexe functie
						insert(tt, '(')
						combineerR(sexp.fn, tt)
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
		if isexp(v) then
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
