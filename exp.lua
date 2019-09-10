--[[
exp = { fn, 1, 2 } | { v }
exp |= { loc, val }
]]
require 'lisp'
require 'util'

function fn(exp) if isfn(exp) then return exp.f.v end end
function atoom(exp,i) 
	if not i then
		return exp.v
	end
	if exp[i] then return exp[i].v end
end

-- checkuhh
local atomen = {}
local lst, b = file('atomen.lst') or file('../atomen.lst')
for atoom in lst:gmatch('[^\n]+') do
	atomen[atoom] = true
end

local objs = set(',', '{}', '[]')

-- itereer kinderen
function subs(exp)

	if isatoom(exp) then
		return function() return nil end
	end

	if isfn(exp) then
		local a = 2
		return function()
			if a == 2 then
				a = 1
				return exp.f
			elseif a == 1 then
				a = 0
				return exp.a
			else
				return nil
			end
		end
	end

	if isobj(exp) then
		local a = true
		local i = 0
		return function()
			if a then
				a = false
				return exp.o
			else
				i = i + 1
				return exp[i]
			end
		end
	end

end

function checkr2(e, p, t)
	local t = t or '  '
	--print(t..(e.v or (e.f and e.f.v) or '?'))
	--assert(e ~= nil, 'is niets (in '..lenc(p)..')')
	--if e.v then print(t..e.v) else print('F=', e.f and e.f.v) end

	-- atoom
	if e.v ~= nil then
		--assert(tonumber(e.v) or atomen[e.v], 'geen getal of atoom: '..e.v)

	-- komma
	elseif e.f ~= nil and objs[e.f.v] then
		checkr(e.f, e, t .. '  ')
		for i,v in ipairs(e) do
			checkr(v, e, t .. '  ')
		end

	-- normale functie
	else
		checkr(e.f, e, t .. '  ')
		checkr(e.a, e, t .. '  ')
	end

	return e
end

function checkr(e)
	assert(e)
	for sub in subs(e) do
		checkr(sub)
	end
end

function check(e)
	local a,b,c = checkr(e, e)
	if not a then
		print(b)
		error('check faalde voor '..e2s(e))
	end
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
	local bron = loc.bron or '?.code'
	bron = bron:sub(1, -6)

	if loc.y1 == loc.y2 and loc.x1 == loc.x2 then
		return string.format("%s@%d:%d", bron, loc.y1, loc.x1)
	elseif loc.y1 == loc.y2 then
		return string.format("%s@%d:%d-%d", bron, loc.y1, loc.x1, loc.x2)
	else
		return string.format("%s@%d:%d-%d:%d", bron, loc.y1, loc.x1, loc.y2, loc.x2)
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

function expmoesR(exp, t)
	if exp.moes then t[#t+1] = tostring(exp.moes); return end
	if isatoom(exp) then t[#t+1] = exp.v
	else
		if not isatoom(exp.f) then t[#t+1] = '(' end
		expmoesR(exp.f, t)
		if not isatoom(exp.f) then t[#t+1] = ')' end
		t[#t+1] = '('
		for i, v in ipairs(exp) do
			expmoesR(v, t)
			if i ~= #exp then t[#t+1] = ' ' end
		end
		t[#t+1] = ')'
	end
end

function expmoes(exp)
	if exp.moes then
		-- niets...
	elseif isatoom(exp) then
		exp.moes = exp.v
	else
		local t = {}
		t[#t+1] = expmoes(exp.f)
		t[#t+1] = '('
		for i=1,#exp do
			t[#t+1] = expmoes(exp[i])
			if i ~= #exp then
				t[#t+1] = ' '
			end
		end
		t[#t+1] = ')'
		exp.moes = table.concat(t)
	end
	return exp.moes
end


function expmoes0(exp)
	---if moezen[exp] then
		---return moezen[exp]
	---end
	local t = {}
	expmoesR(exp, t)
	local moes = table.concat(t)
	---moezen[exp] = moes
	return moes
end
moes = expmoes

function assign(b, a)
	b.moes = nil
	local keys = {}
	for k in pairs(b) do keys[k] = true end
	for k in pairs(keys) do b[k] = nil end
	for k,v in pairs(a) do b[k] = v end
end

-- 1-gebaseerd
-- 1 t/m 26 zijn A t/m Z
-- daarna AA t/m ZZ
-- daarna AAA t/m ZZZ
function varnaam(i)
	local r = ''
	i = i - 1
	repeat
		local c = i % 26
		i = math.floor(i / 26)
		local l = string.char(string.byte('A') + c)
		r = l .. r
	until i == 0
	return r
end

function maakvars()
	local i = 1
	return function ()
		local var = varnaam(i)
		i = i + 1
		return var
	end
end

function maakindices()
	local i = 1
	return function ()
		local var = tostring(i)
		i = i + 1
		return var
	end
end

-- willekeurige volgorde
function boompairs(exp)
	local t = {}
	local function r(exp)
		if not exp.v and not exp.f then error('GEEN EXP!') end
		if exp == nil then error('OEI') end
		if isatoom(exp) then
			t[exp] = true
		else
			t[exp] = true
			if exp.f == nil then
				print('BOVEN::')
				seerec(exp)
				error('WEE')
			end
			r(exp.f)
			for i,v in ipairs(exp) do
				if v == nil then
					error('WEE')
				end
				r(v)
			end
		end
	end
	r(exp)
	
	local k = nil
	return function()
		if next(t,k) then
			k = next(t,k)
			return k
		end
	end
end

-- depth first search
function boompairsdfs(exp)
	local t = {}
	function r(exp)
		if isatoom(exp) then
			t[#t+1] = exp
		else
			r(exp.f)
			for i,v in ipairs(exp) do
				r(v)
			end
			t[#t+1] = exp
		end
	end
	r(exp)
	
	local i = 1
	return function()
		i = i + 1
		return t[i-1]
	end
end

-- breadth first search
function boompairsbfs(exp)
	local t = {}
	function r(exp)
		if isatoom(exp) then
			t[#t+1] = exp
		else
			t[#t+1] = exp
			r(exp.f)
			for i,v in ipairs(exp) do
				r(v)
			end
		end
	end
	r(exp)
	
	local i = 1
	return function()
		i = i + 1
		return t[i-1]
	end
end

function bevat(exp, naam)
	if not exp then error('geen exp') end
	if not exp.v and not exp.f and not exp.o then error('geen exp') end
	if not naam.v then error('naam is geen exp') end

	if exp.v then
		return exp.v == naam.v
	else
		for sub in subs(exp) do
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
			t[#t+1] = exp2string(v)
			t[#t+1] = ' '
		end
		t[#t] = ')'
		return table.concat(t)
	end
	error 'HOORT NIET'
end
e2s = exp2string

if test then
	-- bevat
	local a = X('+', 'a', '2')
	assert(bevat(a, X'a'), exp2string(a))

	-- subs
	local a = X(',', '1', '2')

	local e = subs(a)
	local a,b,c = e(),e(),e()
	assert(a)
	assert(b)
	assert(c)
	assert(a.v == ',', e2s(a))
	assert(b.v == '1', e2s(b))
	assert(c.v == '2', e2s(c))
end
