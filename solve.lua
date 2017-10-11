require 'sexp-util'
require 'sas'
local insert = table.insert
local unparseMexp = compose(unparse, unmulti)
local unparsem = compose(unparse, unmulti)
local parsem = compose(multi, parse)
local us = unparseSexp
local u = unparse

function eq(a, b)
	if atom(a) ~= atom(b) then return false end
	if atom(a) then return a == b end
	if #a ~= #b then return false end
	if a.op ~= b.op then return false end
	for i,v in ipairs(a) do
		if not eq(v, b[i]) then
			return false
		end
	end
	return true
end
assert(eq(parse'1 + 2 + 3', parse'1 + 2 + 3'))
assert(eq(parse'b', parse'b'))
assert(not eq(parse'a', parse'b'))
assert(not eq(parse'a', parse'a + b'))
assert(not eq(parse'a + b + c', parse'a + c + b'))

function subst(what, dst, src)
	if eq(what, src) then
		return dst
	end
	if atom(what) then
		return what
	end
	for i,v in ipairs(what) do
		what[i] = subst(what[i], dst, src)
	end
	return what
end
--assert(unparsem(subst(parsem'a + b', '2', 'b')) == 'a + 2',
--	'subst(...) = '..unparsem(subst(parsem'a + b', '2', 'b')))


function merge(d1, d2)
	local d3 = {}
	for k,v in pairs(d1) do d3[k] = v end
	for k,v in pairs(d2) do d3[k] = v end
	for i,v in ipairs(d1) do insert(d3,v) end
	for i,v in ipairs(d2) do insert(d3,v) end
	return d3
end

-- enkele vergelijkingen oplossen
function solveq(mexp)
	if not atom(mexp) then
		for i,v in ipairs(mexp) do
			mexp[i] = solveq(v)
		end
		if mexp.op == '=' then
			local n1 = isvar(mexp[1])
			local n2 = isvar(mexp[2])
			local c1 = isconstant(mexp[1])
			local c2 = isconstant(mexp[2])
			if n1 and c2 then
				mexp = {op = ':=', mexp[1], mexp[2]}
			elseif c1 and n2 then
				mexp = {op = ':=', mexp[2], mexp[1]}
			end
		end
	end
	return mexp
end


-- <=> and <=>  =>  <=>
function prog(sexp)
	local r = sexp
	local b = true
	return function()
		if r and r[3] and r[3][1] == '<=>' then
			local a = r[3]
			r = r[2]
			return a
		elseif b then
			b = false
			return r
		end
	end
end

local assoc = set{','}
function tomulti(sexp, op)
	if atom(sexp) then return {sexp, op=op} end
	local mexp = {op=op}
	while sexp[1] == mexp.op do
		if sexp[3] then
			insert(mexp, 1, sexp[3])--multi(sexp[3]))
		end
		sexp = sexp[2]
		if not assoc[mexp.op] then
			break
		end
	end
	-- laatste
	insert(mexp, 1, sexp)
	return mexp
end

function multi(sexp)
	local mexp = tomulti(sexp)
	return function()
		local v = mexp[i]
		i = i + 1
		return v
	end
end

local solutions = parse(file('solve.sas'))
-- NAAMRUIMTE
function scope(s,n)
	if isvar(s) then
		return n..'.'..s
	else
		return s
	end
end
solutions = recursive(scope)(solutions, 'axiom')

-- match SOLUTIE met S-EXP, bind in R
function match(sexp, sol, r)
	local r = r or {}

	-- a match (2 + 3)
	if isvar(sol) then
		r[sol] = sexp
		return r
	end

	-- 2 match 2
	if atom(sol) and atom(sexp) then
		if sol ~= sexp then
			return false
		else
			return r
		end
	end

	-- a + b match c + d
	if exp(sol) and exp(sexp) then
		for i in ipairs(sexp) do
			if not match(sexp[i], sol[i], r) then
				return false
			end
		end
		return r
	end

	return false
end

assert(match(parse('a=1 and b=2'), parse('x=y and z=w')))

function subst(sexp, v, k)
	if eq(k, sexp) then return v end
	if atom(sexp) then return sexp end
	local r = {}
	for i,e in ipairs(sexp) do
		r[i] = subst(e, v, k)
	end
	return r
end

function dsubst(sexp, m)
	for k,v in spairs(m) do
		sexp = subst(sexp, v, k)
	end
	return sexp
end

function good(g)
	if exp(g) and g[1] == '=' and isconstant(g[3]) then
		return true
	end
end

-- substitutie solve
function ssolve(sexp)
	for sol in prog(solutions) do
		local m = match(sexp, sol[2])
		if m then
			local g = dsubst(sol[3], m)
			if good(g) then
				return g
			end
		end
	end
end

-- var solve
function vsolve(sexp)
	-- => neemt aan! A,B = C,D
	if exp(sexp) and sexp[1] == '=>' then
		local o = clone(sexp)
		local pre = sexp[2]
		local post = sexp[3]
		local vars = tomulti(pre[2], ',')
		local vals = tomulti(pre[3], ',')
		local asserts = {op='and'}
		for i in ipairs(vars) do
			local var = vars[i]
			local val = vals[i]
			if isvar(var) then
				sexp = subst(sexp, val, var)
			else
				--insert(asserts, pre)--{'=', var, val})
			end
		end
		if #asserts > 0 then
			sprint('asserts',unmulti(asserts))
			sexp = {'=>', unmulti(asserts), sexp}
		end
	end
	return sexp
end

-- meester oplosser
function msolve(sexp)
	sexp = vsolve(sexp)
	while ssolve(sexp) do
		sexp = ssolve(sexp)
		sexp = vsolve(sexp)
	end
	sexp = vsolve(sexp)
	return sexp
end

solve = recursive(msolve)

local src = [[
v = i | t
bv = bi | bt
bv = 'i3e'
bi = 'i' || i || 'e'
v
]]

local src = [[
a = 3
b = 2
a + b
]]


print(unparse(solve(parse(src))))
