require 'util'
require 'lisp-util'
require 'sas'
local insert = table.insert

function unparseProg(prog, vals)
	local res = {}
	for i,v in ipairs(prog) do
		insert(res, 'v')
		insert(res, tostring(i-1))
		insert(res, ' := ')
		insert(res, unsas(v))
		if vals then
			insert(res, '\t\t; ')
			insert(res, unsas(vals[i]))
		end
		if i ~= #prog then
			insert(res, '\n')
		end
	end
	return table.concat(res)
end

-- maakt lijst van expressies
-- (* (+ 1 2) 3)
function compile(sexp)
	local res = {}

	local function work(sexp)
		-- ten eerste onze argumenten
		local self = {}--sexp[1]}
		for i=1,#sexp do
			local arg = sexp[i]
			if exp(arg) then
				work(arg)
				self[i] = 'v'..#res-1
			else
				if i > 1 and isname(arg) and not math[arg] and
						arg ~= 'oo' and arg ~= 'none' then
					error('ongebonden variabele '..arg)
				end
				self[i] = sexp[i]
			end
		end

		insert(res, self)
	end

	if atom(sexp) then
		if isname(sexp) and not math[sexp] and sexp ~= 'oo' and sexp ~=
				'none' then
			error('ongebonden variabele '..sexp)
		end
		insert(res, sexp)
	else
		work(sexp)
	end

	return res
end
