local insert = table.insert
local remove = table.remove
local unpack = table.unpack
local concat = table.concat
local find = string.find
local floor = math.floor

function all(fn, ...)
	local t = {...}
	local function rec(sexp)
		if atom(sexp) then
			return fn(sexp, table.unpack(t))
		else
			for i,v in pairs(sexp) do
				if not rec(v, table.unpack(t)) then
					return false
				end
			end
		end
		return true
	end
	return rec
end

-- recursive starting below
function recursive(fn)
	local rec
	rec = function(sexp, ...)
		if exp(sexp) then
			local res = {}
			for i,v in ipairs(sexp) do
				sexp[i] = rec(v, ...)
			end
		end
		return fn(sexp, ...)
	end
	return rec
end

function spairs(t)
	local keys = {}
	for k,v in pairs(t) do
		table.insert(keys,k)
	end
	table.sort(keys)

	local i = 1
	return function()
		local key = keys[i]
		local val = t[key]
		i = i + 1
		return key,val
	end
end

function sprint(...)
	local t = {...}
	for i,v in ipairs(t) do
		if type(v) == 'table' then
			if v[1] then
				io.write(unparse(v))
			else
				io.write('{')
				for k,v in spairs(v) do
					io.write(tostring(k))
					io.write('=')
					io.write(tostring(v))
					io.write(' ')
				end
				io.write('}')
			end
		else
			io.write(tostring(v))
		end
		io.write('\t')
	end
	io.write('\n')
end

function clone(sexp)
	if atom(sexp) then
		return sexp
	else
		local res = {}
		for i,v in ipairs(sexp) do
			res[i] = clone(v)
		end
		return res
	end
end

function isnumber(sexp)
	return tonumber(sexp)
end
function istext(sexp)
	return atom(sexp) and sexp:sub(1,1)=="'" and sexp:sub(-1)=="'"
end
local esc = {
	e = '\x1B',
	r = '\r', -- cr
	n = '\n', -- nl
	t = '\t',
	['\\'] = '\\',
	['\''] = '\'',
}
function gettext(s)
	local r = s:sub(2,-2)
	r = r:gsub('\\[%dABCDEF][%dABCDEF]', '<hex>')
	r = r:gsub('\\[nrte0\\\']', function (t) return esc[t:sub(2,2)] end)
	return r
end

local keywords = set{'and','or','xor','is','as','in'}
function iskeyword(sexp)
	return keywords[sexp]
end

function isvar(mexp)
	if exp(mexp) then return false end
	return string.match(mexp,'%a[%w%.]*') and not iskeyword(mexp)
end

local constants = set {'in', 'true', 'false', 'tau', 'int', 'text'}
function isname(sexp)
	if constants[sexp] then return false end
	return atom(sexp) and string.match(sexp:sub(1,1), '%a')
end

function isconstant(sexp)
	if atom(sexp) then
		if istext(sexp) or isnumber(sexp) or constants[sexp] then
			return true
		end
	else
		for i,v in ipairs(sexp) do
			if not isconstant(v) then
				return false
			end
		end
		return true
	end
end

--isconstant = all(isconstant)

local assoc = set{'+', '*', '=', 'and', 'or', 'xor'}

function multi(sexp)
	if atom(sexp) then return sexp end
	local mexp = {
		op = sexp[1],
		bindings = {},
		asserts = {},
	}
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

-- 1 + 2 + 3 + 4 -> (+ 1 2 3 4)
function multi2(sexp, op)
	sexp = clone(sexp)
	local res = {op}
	local cur = sexp
	while cur[1] == op do
		insert(res, 2, cur[3])
		cur = cur[2]
	end
	-- laatste
	insert(res, 2, cur)
	return res
end

-- (+ 1 2 3 4) -> 1 + 2 + 3 + 4
function unmulti2(sexp)
	local op = sexp[1]
	if #sexp == 2 then
		return sexp[2]
	else
		local cur = {op, sexp[2], sexp[3]}
		for i=4,#sexp do
			cur = {op, cur, sexp[i]}
		end
		return cur
	end
end

