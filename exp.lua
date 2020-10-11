--[[
exp = { fn, 1, 2 } | { v }
exp |= { loc, val }
]]
require 'lisp'
require 'util'

local calls = set('_', 'call', 'call2', 'call3', 'call4')

function fname(exp)
	return calls[fn(exp)] and atom(arg0(exp))
end

function fn(exp) if isfn(exp) then return exp.f.v end end
function arg(exp) return exp.a end
function obj(exp) if isobj(exp) then return exp.o.v end end
function atom(exp,i) 
	if not exp then return nil end
	if not i then
		return exp.v
	end
	if exp[i] then return exp[i].v end
end

function copy(exp)
	local t = {}
	for k,v in pairs(exp) do
		t[k] = v
	end
	return t
end

function clone(exp)
	if type(exp) ~= 'table' then return exp end
	local t = {}
	for k,sub in pairs(exp) do
		t[k] = clone(sub)
	end
	return t
end

-- itereer kinderen
function subs(exp)

	if isatom(exp) then
		return function() return nil end
	end

	if isfn(exp) then
		local a = 1
		return function()
			if a == 2 then
				a = 1
				return "f", exp.f
			elseif a == 1 then
				a = 0
				return "a", exp.a
			else
				return nil
			end
		end
	end

	if isobj(exp) then
		local a = nil --true
		local i = 0
		return function()
			if a then
				a = nil
				return "o", exp.o
			else
				i = i + 1
				if exp[i] then
					return i, exp[i]
				end
			end
		end
	end

	check(exp)
	error('geen exp: '..lenc(exp))
end

function checkr(e, p, k)
	assert(k)
	if not e then
		error(string.format('%s[%s] = nil', lenc(p), k))
	end
	local n = 0
	if type(e) ~= 'table' then
		print('FAAL!')
		print('Type:')
		see(type(e))
		print('Exp:')
		print(lenc(e))
		print('Parent:')
		see(p)
		for k,v in pairs(p) do print(k..':'); see(v) end
		error'check faalde'
	end
	if isatom(e) then n = n + 1 end
	if isfn(e) then n = n + 1 end
	if isobj(e) then n = n + 1 end
	if n ~= 1 then
		print('FAAL!')
		print('Exp:')
		see(e)
		print('Parent:')
		see(p)
		error'check faalde'
	end
	for k,sub in subs(e) do
		checkr(sub, e, k)
	end
end

function check(e)
	checkr(e, '<parent>', '<key>')
end

expmt = {}

-- locatie stuff
function loclt(a,b)
	if  a.y1 > b.y1 then return false end
	if  a.y1 < b.y1 then return true end
	if  a.x1 > b.x1 then return false end
	if  a.x1 < b.x1 then return true end

	if  a.y2 > b.y2 then return false end
	if  a.y2 < b.y2 then return true end
	if  a.x2 > b.x2 then return false end
	if  a.x2 < b.x2 then return true end
	return false
end

function locfind(code, x, y)
	local pos = 1
	for i=1,y-1 do
		pos = code:find('\n', pos)
		if not pos then return false end
		pos = pos + 1
	end
	pos = pos + x - 1
	if pos > #code+1 then
		return false
	end
	return pos
end

function loctext(loc)
	if not loc then loc = nergens end
	local bron = ''
	if loc.bron then bron = loc.bron:sub(1,-6) .. '@' end

	if not loc.x1 and bron == '' then
		return '?'
	elseif not loc.x1 then
		return bron
	elseif loc.y1 == loc.y2 and loc.x1 == loc.x2 then
		return string.format("%s%d:%d", bron, loc.y1, loc.x1)
	elseif loc.y1 == loc.y2 then
		return string.format("%s%d:%d-%d", bron, loc.y1, loc.x1, loc.x2)
	else
		return string.format("%s%d:%d-%d:%d", bron, loc.y1, loc.x1, loc.y2, loc.x2)
	end
end

function numleaves(exp)
	if isatom(exp) then
		return 1
	else
		local n = 0
		for i,v in ipairs(exp) do
			n = n + numleaves(v)
		end
		return n
	end
end

function locsub(code, loc)
	if not code then return "???" end
	local apos = locfind(code, loc.x1, loc.y1)
	local bpos = locfind(code, loc.x2+1, loc.y2)
	if not apos or not bpos then return false end
	return string.sub(code, apos, bpos-1)
end

function bron(exp)
	if exp.super and obj(exp) == ',' and loctext(exp.loc) == loctext(exp.super.loc) then
		return deparse(exp)
	end
	if not exp.code or not exp.loc then
		return deparse(exp)
	end
	return locsub(exp.code, exp.loc)
end

function hash(exp)
	if exp.hash then
		-- niets...
	else
		exp.hash = e2s(exp)
	end
	return exp.hash
end

function arg0(exp) return exp.a and exp.a[1] end
function arg1(exp) return exp.a and exp.a[2] end
function arg2(exp) return exp.a and exp.a[3] end
function arg3(exp) return exp.a and exp.a[4] end
function arg4(exp) return exp.a and exp.a[5] end

function assign(a, b)
	if a == b then return a end
	local keys = {}
	for k in pairs(a) do keys[k] = true end
	for k in pairs(keys) do a[k] = nil end
	for k,v in pairs(b) do a[k] = v end
	for k,v in pairs(b) do a[k] = v end
	return a
end

-- 1-gebaseerd
-- 1 t/m 26 zijn A t/m Z
-- daarna AA t/m ZZ
-- daarna AAA t/m ZZZ
-- A,B,AA,AB,BA,BB,AAA,AAB,ABA,ABB,BAA,BAB,BBA,BBB,AAAA
function varname(i)
	local i = i - 1
	--assert(i >= 0)
	if i == 0 then return 'A' end
	local r = ''
	while i > 0 do
		local c = i % 26
		i = math.floor(i / 26)
		if r ~= '' then c = c - 1 end
		local l = string.char(string.byte('A') + c)
		if c < 0 then
			l = '_'
		end
		r = l .. r
	end
	return r --r:sub(2)
end

function makevars()
	local i = 1
	return function ()
		local var = varname(i)
		i = i + 1
		return var
	end
end

function maakindices(i)
	local i = i or 1
	return function ()
		local var = i
		i = i + 1
		return var
	end
end

-- breadth first search
function treepairsbfs(exp, t, al)
	local t = t or {}
	local al = al or {}

	local function rec(exp)
		if not al[exp] then
			for k,sub in subs(exp) do
				rec(sub)
			end
			t[#t+1] = exp
			al[exp] = true
		end
	end

	rec(exp)

	local i = 1
	return function()
		i = i + 1
		return t[i-1]
	end
end

treepairs = treepairsbfs

function bevat(exp, name)
	if not exp then error('geen exp') end
	if not exp.v and not exp.f and not exp.o then error('geen exp: '..lenc(exp)) end
	--if not name.v then error('name is geen exp') end

	if exp.v then
		return exp.v == name.v
	else
		if not isatom(name) and hash(exp) == hash(name) then
			return true
		end
		--print('FN', fn(exp), name.v)
		if fn(exp) == atom(name) then
		--print'ja'
			return true
		end
		for k,sub in subs(exp) do
			if bevat(sub, name) then return true end
		end
		return false
	end
end

-- a
-- f(a)
-- f(,(1 2))
function exp2string(exp, klaar)
	local klaar = klaar or {}
	if klaar[exp] then return klaar[exp] end
	klaar[exp] = '~'
	if not exp then return '?' end
	if isatom(exp) then
		return exp.v
	elseif isfn(exp) then
		return string.format('%s(%s)', exp2string(exp.f, klaar), exp2string(exp.a, klaar))
	elseif isobj(exp) then
		local t = {}
		t[#t+1] = exp2string(exp.o, klaar)
		t[#t+1] = '('
		for i,v in ipairs(exp) do
			if i > 1 then
				t[#t+1] = ' '
			end
			t[#t+1] = exp2string(v, klaar)
		end
		t[#t+1] = ')'
		return table.concat(t)
	end
	return '?'
end
e2s = exp2string

local function perhashR(exp, moezen)
	local m = hash(exp)
	moezen[m] = moezen[m] or {}
	moezen[m][#moezen[m]+1] = exp
	for k,sub in subs(exp) do
		perhashR(sub, moezen)
	end
end

function perhash(exp)
	local moezen = {}
	perhashR(exp,  moezen)
	return moezen
end

if test then
	-- bevat
	local a = X('+', 'a', '2')
	assert(bevat(a, X'a'), exp2string(a))

	-- subs
	local a = X(',', '1', '2')

	local e = subs(a)
	local _,a = e()
	local _,b = e()
	assert(a)
	assert(b)
	assert(a.v == '1', e2s(a))
	assert(b.v == '2', e2s(b))
end

-- depth first search
function treepairsdfs1(exp, t, al)
	local t = t or {}
	local al = al or {}
	
	local function rec(exp)
		if not al[exp] then
			for k,sub in subs(exp) do
				rec(sub)
			end
			t[#t+1] = exp
			al[exp] = true
		end
	end

	rec(exp)

	local i = 1
	return function()
		i = i + 1
		return t[i-1]
	end
end

-- werkt niet omdat exp gemuteerd word
function treepairsdfs2(exp)
	local function rec(exp)
		for k, sub in subs(exp) do
			rec(sub)
		end
		--print('YIELD', hash(exp))
		coroutine.yield(exp)
	end
	
	local co = coroutine.create(rec)
	return function()
		local ok,sub = coroutine.resume(co, exp)
		--print('SUB', ok, sub)
		if ok then
			return sub
		end
	end
end

treepairsdfs = treepairsdfs1


function treepairs(exp)
	local function rec(exp)
		for k, sub in subs(exp) do
			rec(sub)
		end
		coroutine.yield(exp)
	end
	
	local co = coroutine.create(rec)
	return function()
		local ok,sub = coroutine.resume(co, exp)
		if ok then
			return sub
		end
	end
end

function treepairsbfs(exp)
	local function rec(exp)
		coroutine.yield(exp)
		for k, sub in subs(exp) do
			rec(sub)
		end
	end
	
	local co = coroutine.create(rec)
	return function()
		local ok,sub = coroutine.resume(co, exp)
		if ok then
			return sub
		end
	end
end
