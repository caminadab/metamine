require 'lisp'

local infix = {
	['^'] = true, ['_'] = true,
	['* '] = true, ['/'] = true,
	['+ '] = true, ['-'] = true,
	['>'] = true, ['<'] = true,
	['>='] = true, ['<='] = true,
}

local vertaal = {
	['+'] = 'plus',
	['*'] = 'keer',
	['of'] = 'of',
	['{}'] = 'agg',
	['sin'] = 'math.sin',
	['cos'] = 'math.cos',
	['abs'] = 'math.abs',
	['.'] = 'index',
	['||'] = 'cat',
	['|'] = 'combineer',
	['&'] = 'multi',
	['sincos'] = 'sincos',
	['=>'] = 'dan',
	['..'] = 'tot',
	['#'] = 'len',
	['='] = 'eq',
}

local function naam2love(naam)
	if type(naam) == 'string' then
		return naam:gsub('.%-.', function (a)
				return a:sub(1,1):lower() .. a:sub(3,3):upper()
		end)
	else
		return naam
	end
end

function tofunc(naar,van,t)
	t[#t+1] = 'function ('
	t[#t+1] = van
	t[#t+1] = ')\n'

	t[#t+1] = 'return '
	tolo(naar, t)
	t[#t+1] = '\n'
	t[#t+1] = 'end'
end

function tolo(exp,t,typen)
	t = t or {}
	if atom(exp) then
		t[#t+1] = vertaal[exp] or naam2love(exp) or exp

	-- schaduw
	elseif exp[1] == "'" then
		local naam = naam2love(exp[2])
		t[#t+1] = 'schaduw_'..naam
		t[#t+1] = ' or '
		t[#t+1] = naam
	elseif exp[1] == '->' then
		tofunc(exp[3], exp[2], t)
	elseif infix[exp[1]] and exp[3] then
		t[#t+1] = '('
		tolo(exp[2], t, typen)
		t[#t+1] = exp[1]
		tolo(exp[3], t, typen)
		t[#t+1] = ')'
	elseif exp[1] == '[]' then
		t[#t+1] = '{'
		for i=2,#exp do
			if i == 2 then
				t[#t+1] = '[0] = '
			end
			tolo(exp[i], t, typen)
			if i ~= #exp then
				t[#t+1] = ', '
			end
		end
		t[#t+1] = '}'
	elseif isexp(typen[exp[1]]) and typen[exp[1]][1] == '^' then
		tolo(exp[1], t, typen)
		t[#t+1] = ''
		t[#t+1] = '['
		for i=2,#exp do
			tolo(exp[i], t, typen)
			t[#t+1] = ', '
		end
		t[#t] = nil
		t[#t+1] = ']'
	else
		tolo(exp[1], t, typen)
		t[#t+1] = ''
		t[#t+1] = '('
		for i=2,#exp do
			tolo(exp[i], t, typen)
			t[#t+1] = ', '
		end
		t[#t] = nil
		t[#t+1] = ')'
	end
	return t
end

function stat2love(stat,t,vars,typen)
	local doel = stat[2]
	local naam
	if isexp(doel) then
		t[#t+1] = doel[1]..' = {}\n'
		naam = doel[1]..'['..doel[2]..']'
		local len = doel[2]
		t[#t+1] = 'for '..len..'=0,-1+#'..len..' do\n'
	else
		naam = doel
	end
	t[#t+1] = naam2love(naam)
	t[#t+1] = ' = '
	tolo(stat[3],t,typen)
	t[#t+1] = '\n'
	vars[#vars+1] = stat[2]
	if isexp(doel) then
		t[#t+1] = 'end\n'
	end
end

-- toetsen
local toets = {
	'rechts', 'links', 'omhoog', 'omlaag',
	'spatie',
	'a', 's', 'd', 'f', 'h', 'j', 'k', 'l',
}

local engels = {
	rechts = 'right',
	links = 'left',
	omhoog = 'up',
	omlaag = 'down',
	spatie = 'space',
}

function tolove(block,typen)

	local t = {
[[
package.path = package.path .. ';../?.lua'
local function len(a) return #a+1 end
local function of(a,b) return a or b end
local function agg(...)
	-- functies
	local a = {...}
	--local r = {}
	for i,v in ipairs(a) do
		if v then return v end
		--r[v] = true
		-- conditie, feit
		--local c,f = v[2],v[3]
		--r[c] = f
	end
	return false
end
local function tot(a,b)
	local r = {}
	local j = 0
	for i=a,b-1 do
		r[j] = i
		j = j + 1
	end
	return r
end

local function plus(a,b) if tonumber(a) and tonumber(b) then return a + b end end
local function keer(a,b) if tonumber(a) and tonumber(b) then return a * b end end

local function combineer(a,b)
	if a and b and a ~= b then error('meerdere waarden passen niet in enkele variabele: '..tostring(a)..' en '..tostring(b)) end
	if b then return b end
	if a then return a end
	return nil
end

local function index(a,b)
	return a[b]
end

local function som(a)
	local som = 0
	for i,v in pairs(a) do
		som = som + v
	end
	return som
end
local function sincos(hoek)
	return {math.cos(hoek), math.sin(hoek)}
end

local function dan(cond,v)
	if cond then
		return v
	else
		return nil
	end
end

local function eq(a,b)
	if type(a) == 'number' and type(b) == 'number' then
		return math.abs(a-b) < 1e-2
	else
		return a == b
	end
end
local bag = {}
local function var(ass)
	for cond in pairs(ass) do
		if cond then
			bag[ass] = cond
			return cond
		end
	end
	return bag[ass] or 0
end
VROEGER = 0
start = love.timer.getTime()
nu = start

]] }

	-- vars
	for i,toets in ipairs(toets) do
		local naam = toets:gsub("^%l", string.upper) -- Links
		t[#t+1] = 'toets'..naam..' = '..'{ }\n'
		t[#t+1] = 'for i=0,599 do toets'..naam..'[i] = 0 end\n'
		t[#t+1] = 'local toets'..naam..'Aan = 0\n'
		t[#t+1] = 'local toets'..naam..'Uit = 0\n'
	end

	t[#t+1] = [[local prevSpaceDown = false

local toetsSpatieAan = false
local toetsSpatieUit = false
]]

	-- update
	local vars = {}
	t[#t+1] = 'function love.update()\n'

	-- update toets
	for i,toets in ipairs(toets) do
		local naam = toets:gsub("^%l", string.upper) -- Links
		--t[#t+1] = 'toets'..naam..' = '..'{ }\n'
		--t[#t+1] = 'for i=1,600 do toets'..naam..'[i] = 0 end\n'
		t[#t+1] = 'for i=0,600-1 do toets'..naam..'[i] = toets'..naam..'[i+1] or 0 end\n'
		t[#t+1]  = 'toets'..naam..'[600] = (love.keyboard.isDown("'..(engels[toets] or toets)..'") and 1/60 or 0)\n'
	end

	t[#t+1] = [[
	-- update toets
	toetsSpatieAan = false
	toetsSpatieUit = false

	if love.keyboard.isDown("space") and prevSpaceDown == false then
		prevSpaceDown = true
		toetsSpatieAan = true
	elseif not love.keyboard.isDown("space") and prevSpaceDown == true then
		prevSpaceDown = false
		toetsSpatieUit = true
	end
]]

	for i=1,#block do
		local stat = block[i]
		stat2love(stat,t,vars,typen)
	end

	-- schaduw
	for i,stat in ipairs(block) do
		local naam = stat[2]
		t[#t+1] = 'schaduw_'..naam2love(naam)
		t[#t+1] = ' = '
		t[#t+1] = naam2love(naam)
		t[#t+1] = '\n'
	end

	-- paraguay
	beeld = nu
	t[#t+1] = [[
		nu = love.timer.getTime()
		beeld = nu
	end
]]

	-- draw
	t[#t+1] = [[
local lgsc = love.graphics.setColor
love.graphics.setColor = function(r,g,b,a)
	local a = a or 1
	lgsc(r*255,g*255,b*255,a*255)
	--lgsc(254,255,255,255)
end

function love.draw()
	if stip and stip[0] and stip[1] then
		love.graphics.circle('fill', stip[0], stip[1], stip[2] or 20)
	end
]]

	-- code
	if code then
		t[#t+1] = 'love.graphics.print('..string.format('%q',code)..', 500, 10)\n'
	end
	
	-- grafiek
	t[#t+1] = [[
	local sx,sy = 10,310
	local x,y = sx,sy
	love.graphics.setLineJoin('none')

	function grafiek(lijst,sx,sy,w,h)
		local w = w or 600--#lijst
		local h = h or 20
		local xsch = 1
		local ysch = 1
		--local vx,vy = xsch*0, lijst[1]*ysch
		local p = {}
		local vx,vy
		for i=1,#lijst do
			local x = xsch * i
			local y = ysch * lijst[i]
			local bx,by = sx+x, sy+h - y*h*60

			-- horiz
			if vy ~= by or i == 1 or i == 600 then
				p[#p+1] = (vx or bx)
				p[#p+1] = (vy or by)
				p[#p+1] = bx
				p[#p+1] = by
			end
			vx,vy = bx,by
		end

		love.graphics.setLineStyle('rough')
		if #p < 2 then
			love.graphics.print('niet genoeg data',sx,sy)
		else
			love.graphics.line(p)
		end
	end

	-- grafieken
	]]
	for i,toets in ipairs(toets) do
		local naam = toets:gsub("^%l", string.upper) -- Links
		t[#t+1] = 'love.graphics.setColor(0,.05*'..i..',1) grafiek(toets'..naam..', 20, 120+10*'..i..',100,6)\n'
	end

	t[#t+1] = [[
	love.graphics.setColor(1,1,1)
	love.graphics.reset()

	-- framerate
	local w
	if love.graphics.getWidth then w = love.graphics.getWidth()
	else w = love.window.getWidth() end
	love.graphics.print(tostring(love.timer.getFPS()), w - 30, 10)
]]

	-- debug tekst
	t[#t+1] = ''--[[for i,var in ipairs(vars) do
		t[#t+1] = '\tlove.graphics.print('
		t[#t+1] = '"'..var..' = "..unlisp('
		t[#t+1] = naam2love(var)
		t[#t+1] = '), 10, ' .. i*16 .. ')\n'
	end
	]]

	t[#t+1] = [[end]]

	return table.concat(t)
end
