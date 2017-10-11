require 'util'
local insert = table.insert

function isnumber(sexp)
	return tonumber(sexp)
end
function istext(sexp)
	return atom(sexp) and sexp:sub(1,1)=="'" and sexp:sub(-1)=="'"
end
function gettext(sexp)
	return sexp:sub(2,-2)
end
function totext(sexp)
	return "'"..sexp.."'"
end

function tosas(v)
	if type(v) == 'string' then
		return totext(v)
	elseif type(v) == 'number' then
		return tostring(v)
	elseif type(v) == 'table' then
		local res = {}
		insert(res, '[')
		for i,n in pairs(v) do
			insert(res, tosas(n))
			if next(v,i) then
				insert(res, ',')
			end
		end
		insert(res, ']')
		return table.concat(res, '')
	elseif type(v) == 'boolean' then
		return tostring(v)
	else
		return 'none'
	end
end

function unparseProg(prog, vals)
	local res = {}
	for i,v in ipairs(prog) do
		insert(res, 'v')
		insert(res, tostring(i-1))
		insert(res, ' := ')
		insert(res, unparseInfix(v))
		if vals then
			insert(res, '\t\t; ')
			insert(res, tosas(vals[i]))
		end
		if i ~= #prog then
			insert(res, '\n')
		end
	end
	return table.concat(res)
end

-- maakt lijst van expressies
-- (* (+ 1 2) 3)
local insert = table.insert
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
				if i > 1 and isname(arg) then
					error('ongebonden variabele '..arg)
				end
				self[i] = sexp[i]
			end
		end

		insert(res, self)
	end

	if atom(sexp) then
		if isname(sexp) then
			error('ongebonden variabele '..sexp)
		end
		insert(res, sexp)
	else
		work(sexp)
	end

	return res
end

