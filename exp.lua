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

function checkr(e)
	assert(e ~= nil, 'is niets')

	-- atoom
	if e.v ~= nil then
		--assert(tonumber(e.v) or atomen[e.v], 'geen getal of atoom: '..e.v)

	-- komma
	elseif e.f ~= nil and e.f.v == ',' then
		for i,v in ipairs(e) do
			check(v)
		end

	-- normale functie
	else
		check(e.f)
		check(e.a)
	end

	return e
end

function check(e)
	local a,b,c = checkr(e)
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

function exp2string(self,tabs)
	if type(self) ~= 'table' then return error('is geen expressie') end
	if not self.v and not self.f then error('is geen expressie') end
	return unlisp(self)
end

function exp2stringidk(self,tabs)
	if type(self) == 'string' then return self end
	local tabs = (tabs or '') .. '  '
	local params = {}
	local len = 2 -- '(' & ')'
	for k,param in pairs(self) do
		if type(param) == 'function' then
			param = 'FUNC'
		end
		params[k] = tostring(param,tabs..'  ')
		len = len + #params[k] + 1 -- ' '
	end
	-- =(a,b)

	local fn
	if isfn(self) then
		fn = '('..expmt.__tostring(params.f,tabs..'  ')..')'
	else
		fn = tostring(params.f)
	end
	if len > 30 then
		local a = fn .. '\n' .. tabs .. table.concat(params, '\n'..tabs)
	else
		return fn..'('..table.concat(params,sep)..')'
	end
end
e2s = exp2string


expmt.__tostring = exp2string

function expmt:__eq(ander)
	do
		return self:moes() == ander:moes()
	end

	local zelf = self
	if isatoom(zelf) ~= isatoom(ander) then return false end
	if isatoom(zelf) then return zelf == ander end
	if zelf.f ~= ander.f then return false end
	if #zelf ~= #ander then return false end
	for i=1,#zelf do
		if zelf[i] ~= ander[i] then
			return false
		end
	end
	return true
end

function bevat(exp, naam)
	if not exp then error('geen exp') end
	if not exp.v and not exp.f then error('geen exp') end
	if not naam.v then error('naam is geen exp') end

	if exp.v then
		return exp.v == naam.v
	else
		if bevat(exp.f, naam) then return true end
		for i,v in ipairs(exp) do
			if bevat(v, naam) then return true end
		end
		return false
	end
end

function T(tabs)
	do return unlisp(self) end
	if type(self) == 'string' then return self end
	local tabs = (tabs or '') .. '  '
	local params = {}
	local len = 2 -- '(' & ')'
	for k,param in pairs(self) do
		if type(param) == 'function' then
			param = 'FUNC'
		end
		params[k] = tostring(param,tabs..'  ')
		len = len + #params[k] + 1 -- ' '
	end
	-- =(a,b)

	local fn
	if isfn(self.f) then
		fn = '('..expmt.__tostring(params.f,tabs..'  ')..')'
	else
		fn = tostring(params.f)
	end
	if len > 30 then
		return fn .. '\n' .. tabs .. table.concat(params, '\n'..tabs)
	else
		return fn..'('..table.concat(params,sep)..')'
	end
end

if test then
	-- bevat
	local a = X('+', 'a', '2')
	assert(bevat(a, X'a'), exp2string(a))
end
