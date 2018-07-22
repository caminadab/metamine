require 'lisp'

local infix = {
	['^'] = true, ['_'] = true,
	['*'] = true, ['/'] = true,
	['+'] = true, ['-'] = true,
}

local vertaal = {
	['nu'] = 'love.timer.getTime()',
	['sin'] = 'math.sin',
	['cos'] = 'math.cos',
	['abs'] = 'math.abs',
	['.'] = 'index',
	['||'] = 'cat',
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

function tolo(exp,t)
	t = t or {}
	if atom(exp) then
		t[#t+1] = vertaal[exp] or naam2love(exp) or exp
	elseif exp[1] == '->' then
		tofunc(exp[3], exp[2], t)
	elseif infix[exp[1]] and exp[3] then
		t[#t+1] = '('
		tolo(exp[2], t)
		t[#t+1] = exp[1]
		tolo(exp[3], t)
		t[#t+1] = ')'
	elseif exp[1] == '[]' then
		t[#t+1] = '{'
		for i=2,#exp do
			tolo(exp[i], t)
			if i ~= #exp then
				t[#t+1] = ', '
			end
		end
		t[#t+1] = '}'
	else
		tolo(exp[1], t)
		t[#t+1] = ' '
		t[#t+1] = '('
		for i=2,#exp do
			tolo(exp[i], t)
			t[#t+1] = ', '
		end
		t[#t] = nil
		t[#t+1] = ')'
	end
	return t
end

function stat2love(stat,t,vars)
	t[#t+1] = naam2love(stat[2])
	t[#t+1] = ' = '
	tolo(stat[3],t)
	t[#t+1] = '\n'
	vars[#vars+1] = stat[2]
end

function tolove(block)
	local t = {
[[
package.path = package.path .. ';../?.lua'
local function index(a,b)
	return a[b+1]
end
local function som(a)
	local som = 0
	for i,v in pairs(a) do
		som = som + v
	end
	return som
end

local toetsRechts = {}
local toetsLinks = {}
local toetsOmhoog = {}
local toetsOmlaag = {}
for i=1,600 do toetsRechts[i] = 0 end
for i=1,600 do toetsLinks[i] = 0 end
for i=1,600 do toetsOmhoog[i] = 0 end
for i=1,600 do toetsOmlaag[i] = 0 end
]]}

	-- update
	local vars = {}
	t[#t+1] = 'function love.update()\n'

	-- update toets
	t[#t+1] = [[
	for i=1,600 do toetsRechts[i] = toetsRechts[i+1] end
	for i=1,600 do toetsLinks[i] = toetsLinks[i+1] end
	for i=1,600 do toetsOmhoog[i] = toetsOmhoog[i+1] end
	for i=1,600 do toetsOmlaag[i] = toetsOmlaag[i+1] end
	toetsRechts[600] = (love.keyboard.isDown("right") and 1/60 or 0)
	toetsLinks[600] = (love.keyboard.isDown("left") and 1/60 or 0)
	toetsOmhoog[600] = (love.keyboard.isDown("up") and 1/60 or 0)
	toetsOmlaag[600] = (love.keyboard.isDown("down") and 1/60 or 0)
]]

	for i=1,#block do
		local stat = block[i]
		stat2love(stat,t,vars)
	end
	t[#t+1] = 'end\n'

	-- draw
	t[#t+1] = [[
require 'lisp'
function love.draw()
	love.graphics.circle('fill', cirkel[1], cirkel[2], cirkel[3] or 20)
]]

	for i,var in ipairs(vars) do
		t[#t+1] = '\tlove.graphics.print('
		t[#t+1] = '"'..var..' = "..unlisp('
		t[#t+1] = naam2love(var)
		t[#t+1] = '), 10, ' .. i*16 .. ')\n'
	end

	t[#t+1] = [[end]]

	return table.concat(t)
end
