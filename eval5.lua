require 'compile'
require 'interpret'
require 'sas'
local insert = table.insert
local remove = table.remove
local unpack = table.unpack
local concat = table.concat
local find = string.find

local assoc = set{'+', '=', 'and', 'or', 'xor', 'nor', '*'}

function multi(sexp)
	if atom(sexp) then return sexp end
	local mexp = {op = sexp[1]}
	while sexp[1] == mexp.op do
		if sexp[3] then
			insert(mexp, 1, multi(sexp[3]))
		end
		sexp = sexp[2]
		if not assoc[mexp.op] then
			break
		end
	end
	-- laatste
	insert(mexp, 1, multi(sexp))
	return mexp
end

-- (+ 1 2 3 4) -> 1 + 2 + 3 + 4
function unmulti(mexp)
	if atom(mexp) then
		return mexp
	end
	if #mexp == 1 then
		return {mexp.op, unmulti(mexp[1])}
	end
	local sexp = unmulti(mexp[1])
	for i=2,#mexp do
		sexp = {mexp.op, sexp, unmulti(mexp[i])}
	end
	return sexp
end

function isconstant(sexp)
	if sexp == nil then
		error('rommel')
	elseif istext(sexp) then
		return true
	elseif atom(sexp) then
		return string.match(sexp:sub(1,1), '[%-%d\']')
	else
		if sexp[1] == '|' then
			return false
		end
		local c = true
		for i=2,#sexp do
			if not isconstant(sexp[i]) then
				c = false
				break
			end
		end
		return c
	end
end

function group(mexp)
	if atom(mexp) then
		if isconstant(mexp) then
			return {op='&', 'constant', 'input'}
		else
			return {op='&', 'output'}
		end
	else
		local g = {op=mexp.op} for i,v in ipairs(mexp) do g[i] = group(v)
		end
		return g
	end
end

unparseMexp = curry(unparseSexp, unmulti)
unparsem = curry(unparse, unmulti)
parsem = curry(multi, parse)

local solutions = parsem([[
(a + b), (constant + number), (b + a)
(a + b = c), (number + constant = constant), (a = c - b)
true
]])[1]

local a = parsem "1 + a = 2"
local g = group(a)
print(unparsem(g))

-- (a + b): (int + int) 
function solve(mexp)
	for i,solution in ipairs(solutions) do
		print(unparsem(solution))
		if 
	end
	--[[ recurseer
	if exp(mexp) then
		for i,v in ipairs(mexp) do
			mexp[i] = solve(v)
		end
	end
	]]

	return mexp
end

function eval(sexp)
	local mexp = multi(sexp)
	local sexp = unmulti(solve(mexp))
	local prog = compile(sexp)
	return interpret(compile(sexp))
end
