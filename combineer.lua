require 'lisp'
require 'func'
require 'set'

local insert = table.insert

local binop = set('+', '-', '*', '/', '^', 'en', 'of', '@', '=>')

local function combineerR(sexp, tt)
	if isatoom(sexp) then
		insert(tt, sexp.v)
	else
		local op = sexp.fn.v

		-- lijst/set
		if op == '[]' or op == '{}' then
			insert(tt, op:sub(1,1))
			for i=1,#sexp do
				combineerR(sexp[i], tt)
				if i ~= #sexp then
					insert(tt, ', ')
				end
			end
			insert(tt, op:sub(2,2))

		-- navoegsel
		elseif op == '%' or op == "'" then
			combineerR(sexp[1], tt)
			insert(tt, op)

		-- unop
		elseif #sexp == 1 then
			insert(tt, op)
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
				local br = isfn(v) and binop[v[1]] and binop[op] and binop[v[1]] <= binop[op]

				if br then insert(tt, '(') end

				combineerR(sexp[i], tt)

				if br then insert(tt, ')') end

				if i ~= #sexp then
					if op ~= ',' and op ~= '^' then
						insert(tt, ' ')
					end
					insert(tt, op)
					if op ~= ',' and op ~= '^' then
						insert(tt, ' ')
					end
				end

			end

		-- n-air
		else
			insert(tt, op)
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
