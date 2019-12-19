--[[
exp = { fn, 1, 2 } | { v }
exp |= { loc, val }
]]
require 'lisp'
require 'util'

function fn(exp) if isfn(exp) then return exp.f.v end end
function arg(exp) if isfn(exp) then return exp.a end end
function obj(exp) if isobj(exp) then return exp.o.v end end
function atoom(exp,i) 
	if not i then
		return exp.v
	end
	if exp[i] then return exp[i].v end
end

function kopieer(exp)
	local t = {}
	for k,v in pairs(exp) do
		t[k] = v
	end
	return t
end

function kloon(exp)
	if type(exp) ~= 'table' then return exp end
	local t = {}
	for k,sub in pairs(exp) do
		t[k] = kloon(sub)
	end
	return t
end

-- checkuhh
local atomen = {}
local lst, fout = file('atomen.lst') or file('../atomen.lst')
for atoom in lst:gmatch('[^\n]+') do
	atomen[atoom] = true
end

local objs = set(',', '{}', '[]', '[]u')

-- itereer kinderen
function subs(exp)

	if isatoom(exp) then
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
	if isatoom(e) then n = n + 1 end
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

function locvind(code, x, y)
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

function loctekst(loc)
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

function bladeren(exp)
	if isatoom(exp) then
		return 1
	else
		local n = 0
		for i,v in ipairs(exp) do
			n = n + bladeren(v)
		end
		return n
	end
end

function locsub(code, loc)
	if not code then return "???" end
	local apos = locvind(code, loc.x1, loc.y1)
	local bpos = locvind(code, loc.x2+1, loc.y2)
	if not apos or not bpos then return false end
	return string.sub(code, apos, bpos-1)
end

function bron(exp)
	if exp.super and obj(exp) == ',' and loctekst(exp.loc) == loctekst(exp.super.loc) then
		return combineer(exp)
	end
	if not exp.code or not exp.loc then
		return combineer(exp)
	end
	return locsub(exp.code, exp.loc)
end

function moes(exp)
	if exp.moes then
		-- niets...
	else
		exp.moes = e2s(exp)
	end
	return exp.moes
end

function arg0(exp)
	return exp.a and exp.a[1]
end

function arg1(exp)
	return exp.a and exp.a[2]
end

function arg2(exp)
	return exp.a and exp.a[3]
end

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
function varnaam(i)
	local i = i - 1
	if i == 0 then return 'A' end
	local r = ''
	while i > 0 do
		local c = i % 26
		i = math.floor(i / 26)
		if r ~= '' then c = c - 1 end
		local l = string.char(string.byte('A') + c)
		r = l .. r
	end
	return r --r:sub(2)
end

function maakvars()
	local i = 1
	return function ()
		local var = varnaam(i)
		i = i + 1
		return var
	end
end

function maakindices(i)
	local i = i or 1
	return function ()
		local var = tostring(i)
		i = i + 1
		return var
	end
end

-- depth first search
function boompairsdfs(exp, t)
	local t = t or {}
	for k,sub in subs(exp) do
		boompairsdfs(sub, t)
	end
	t[#t+1] = exp

	local i = 1
	return function()
		i = i + 1
		return t[i-1]
	end
end

-- breadth first search
function boompairsbfs(exp, t)
	local t = t or {}
	for k,sub in subs(exp) do
		boompairsdfs(sub, t)
	end
	t[#t+1] = exp

	local i = 1
	return function()
		i = i + 1
		return t[i-1]
	end
end

boompairs = boompairsbfs

function bevat(exp, naam)
	if not exp then error('geen exp') end
	if not exp.v and not exp.f and not exp.o then error('geen exp') end
	if not naam.v then error('naam is geen exp') end

	if exp.v then
		return exp.v == naam.v
	else
		for k,sub in subs(exp) do
			if bevat(sub, naam) then return true end
		end
		return false
	end
end

-- a
-- f(a)
-- f(,(1 2))
function exp2string(exp)
	if not exp then return '?' end
	if isatoom(exp) then
		return exp.v
	elseif isfn(exp) then
		return string.format('%s(%s)', exp2string(exp.f), exp2string(exp.a))
	elseif isobj(exp) then
		local t = {}
		t[#t+1] = exp2string(exp.o)
		t[#t+1] = '('
		for i,v in ipairs(exp) do
			if i > 1 then
				t[#t+1] = ' '
			end
			t[#t+1] = exp2string(v)
		end
		t[#t+1] = ')'
		return table.concat(t)
	end
	return '?'
end
e2s = exp2string

local function permoesR(exp, moezen)
	local m = moes(exp)
	moezen[m] = moezen[m] or {}
	moezen[m][#moezen[m]+1] = exp
	for k,sub in subs(exp) do
		permoesR(sub, moezen)
	end
end

function permoes(exp)
	local moezen = {}
	permoesR(exp,  moezen)
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
