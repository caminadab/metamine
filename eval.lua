require 'compile'
require 'interpret'
require 'sas'
local insert = table.insert
local remove = table.remove
local unpack = table.unpack
local concat = table.concat
local find = string.find

local assoc = {
	['+'] = true, ['='] = true,
	['and'] = true, ['or'] = true, ['xor'] = true, ['nor'] = true,
	['*'] = true,
}

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

function solve(mexp)
	-- recurseer
	if exp(mexp) then
		for i,v in ipairs(mexp) do
			mexp[i] = solve(v)
		end
	end

	return mexp
end

function eval(sexp)
	local mexp = multi(sexp)
	local sexp = unmulti(solve(mexp))
	local prog = compile(sexp)
	return interpret(compile(sexp))
end
