#!/usr/bin/lua5.2
require 'lisp'

local proc = lisp(io.stdin:read('*a'))

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
}

function tolo(exp,t)
	t = t or {}
	if atom(exp) then
		t[#t+1] = vertaal[exp] or exp
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
			t[#t+1] = ', '
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

function tolove(proc)
	local t = {
[[
local function index(a,b)
	return a[b+1]
end
]]}

	-- update
	local vars = {}
	for i,block in ipairs(proc) do
		if block[1] == 'const' then
			for i=2,#block do
				local stat = block[i]
				t[#t+1] = stat[2]
				t[#t+1] = ' = '
				tolo(stat[3],t)
				t[#t+1] = '\n'
				vars[#vars+1] = stat[2]
			end
		end
		if block[1] == 'sec' then
			t[#t+1] = 'function love.update()\n'
			for i=2,#block do
				local stat = block[i]
				t[#t+1] = '\t'
				t[#t+1] = stat[2]
				t[#t+1] = ' = '
				tolo(stat[3],t)
				t[#t+1] = '\n'
				vars[#vars+1] = stat[2]
			end
			t[#t+1] = 'end\n'
		end
	end

	-- draw
	t[#t+1] = [[
require 'lisp'
love.window.setMode(1280,1024,{fullscreen=true})
function love.draw()
	for i,v in ipairs(stdout) do
		love.graphics.circle('fill', v[1], v[2], 20)
	end
	]]

	for i,var in ipairs(vars) do
		t[#t+1] = '\tlove.graphics.print('
		t[#t+1] = '"'..var..' = "..unlisp('
		t[#t+1] = var
		t[#t+1] = '), 10, ' .. i*16 .. ')\n'
	end

	t[#t+1] = [[end]]

	return table.concat(t)
end

print(tolove(proc))
