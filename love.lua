require 'lisp'

local infix = {
	['^'] = true, ['_'] = true,
	['*'] = true, ['/'] = true,
	['+'] = true, ['-'] = true,
	['>'] = true, ['<'] = true,
	['>='] = true, ['<='] = true,
}

local vertaal = {
	['of'] = 'of',
	['{}'] = 'agg',
	['sin'] = 'math.sin',
	['cos'] = 'math.cos',
	['abs'] = 'math.abs',
	['.'] = 'index',
	['||'] = 'cat',
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

function tolove(block,typen)
	local t = {
[[
package.path = package.path .. ';../?.lua'
local function len(a) return #a+1 end
local function of(a,b) return a or b end
local function agg(...)
	-- functies
	local a = {...}
	local r = {}
	for i,v in ipairs(a) do
		r[v] = true
		-- conditie, feit
		--local c,f = v[2],v[3]
		--r[c] = f
	end
	return r
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
		return math.abs(a-b) < 1e-3
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

local toetsRechts = {}
local toetsLinks = {}
local toetsOmhoog = {}
local toetsOmlaag = {}
local toetsSpatie = {}
for i=1,600 do toetsRechts[i] = 0 end
for i=1,600 do toetsLinks[i] = 0 end
for i=1,600 do toetsOmhoog[i] = 0 end
for i=1,600 do toetsOmlaag[i] = 0 end
for i=1,600 do toetsSpatie[i] = 0 end
local prevSpaceDown = false
local toetsSpatieAan = 0
local toetsSpatieUit = 0
]]}

	-- update
	local vars = {}
	t[#t+1] = 'function love.update()\n'

	-- update toets
	t[#t+1] = [[
	-- update toets
	for i=1,600-1 do toetsRechts[i] = toetsRechts[i+1] end
	for i=1,600-1 do toetsLinks[i] = toetsLinks[i+1] end
	for i=1,600-1 do toetsOmhoog[i] = toetsOmhoog[i+1] end
	for i=1,600-1 do toetsOmlaag[i] = toetsOmlaag[i+1] end
	for i=1,600-1 do toetsSpatie[i] = toetsSpatie[i+1] end
	toetsRechts[600] = (love.keyboard.isDown("right") and 1/60 or 0)
	toetsLinks[600] = (love.keyboard.isDown("left") and 1/60 or 0)
	toetsOmhoog[600] = (love.keyboard.isDown("up") and 1/60 or 0)
	toetsOmlaag[600] = (love.keyboard.isDown("down") and 1/60 or 0)
	toetsSpatie[600] = ((love.keyboard.isDown("space")) and 1/60 or 0)

	if toetsSpatieAan > 0 then toetsSpatieAan = toetsSpatieAan - 1 end
	if toetsSpatieUit > 0 then toetsSpatieUit = toetsSpatieUit - 1 end

	if love.keyboard.isDown("space") and prevSpaceDown == false then
		prevSpaceDown = true
		toetsSpatieAan = 600
	elseif not love.keyboard.isDown("space") and prevSpaceDown == true then
		prevSpaceDown = false
		toetsSpatieUit = 600
	end
]]

	for i=1,#block do
		local stat = block[i]
		stat2love(stat,t,vars,typen)
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
	if cirkel and cirkel[0] and cirkel[1] then
		love.graphics.circle('fill', cirkel[0], cirkel[1], cirkel[2] or 20)
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
		love.graphics.line(p)
	end

	-- grafieken
	love.graphics.setColor(0,.9,1) grafiek(toetsRechts,	20, 320)
	love.graphics.setColor(0,.7,1) grafiek(toetsLinks,		20, 350)
	love.graphics.setColor(0,.5,1) grafiek(toetsOmhoog,	20, 380)
	love.graphics.setColor(0,.3,1) grafiek(toetsOmlaag,	20, 410)
	love.graphics.setColor(0,.1,1) grafiek(toetsSpatie,	20, 440)
	love.graphics.setColor(1,1,1)
	love.graphics.reset()

	-- framerate
	local w
	if love.graphics.getWidth then w = love.graphics.getWidth()
	else w = love.window.getWidth() end
	love.graphics.print(tostring(love.timer.getFPS()), w - 30, 10)
]]

	-- debug tekst
	--[[for i,var in ipairs(vars) do
		t[#t+1] = '\tlove.graphics.print('
		t[#t+1] = '"'..var..' = "..unlisp('
		t[#t+1] = naam2love(var)
		t[#t+1] = '), 10, ' .. i*16 .. ')\n'
	end]]

	t[#t+1] = [[end]]

	return table.concat(t)
end
