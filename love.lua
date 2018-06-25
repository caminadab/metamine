require 'lisp'

local infix = {
	['^'] = true, ['_'] = true,
	['*'] = true, ['/'] = true,
	['+'] = true, ['-'] = true,
}

local vertaal = {
	['tijd'] = 'love.timer.getTime()',
	['sin'] = 'math.sin',
	['cos'] = 'math.cos',
	['.'] = 'index',
	['toets-links'] = '(love.keyboard.isDown("left") and 1 or 0)',
	['toets-rechts'] = '(love.keyboard.isDown("right") and 1 or 0)',
	['toets-omhoog'] = '(love.keyboard.isDown("up") and 1 or 0)',
	['toets-omlaag'] = '(love.keyboard.isDown("down") and 1 or 0)',
}

local function naam2love(naam)
	return naam:gsub('(-.)', function (chars)
		return chars:sub(2,2):upper()
	end)
end

function tolo(exp,t)
	t = t or {}
	if atom(exp) then
		t[#t+1] = vertaal[exp] or naam2love(exp)
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
[[local function index(a,b)
	return a[b+1]
end
]]}

	-- update
	local vars = {}
	t[#t+1] = 'function love.update()\n'
	for i=1,#block do
		local stat = block[i]
		stat2love(stat,t,vars)
	end
	t[#t+1] = 'end\n'

	-- draw
	t[#t+1] = [[
require 'lisp'
--love.window.setMode(1280,1024,{fullscreen=true})
function love.draw()
	for i,v in ipairs(uit) do
		love.graphics.circle('fill', v[1], v[2], 20)
	end
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
