require 'lisp'

local infix = {
	['^'] = true, ['_'] = true,
	['*'] = true, ['/'] = true,
	['+'] = true, ['-'] = true,
}

local vertaal = {
	['tijd'] = 'Date.now()',
	['sin'] = 'Math.sin',
	['cos'] = 'Math.cos',
	['abs'] = 'Math.abs',
	['.'] = 'index',
	['||'] = 'cat',
}

local function _naam2js(naam)
	if type(naam) == 'string' then
		return naam:gsub('.%-.', function (a)
				return a:sub(1,1):lower() .. a:sub(3,3):upper()
		end)
	else
		return naam
	end
end

local function naam2js(naam)
	if type(naam) == 'string' then
		local r = {}
		for i=1,#naam do
			if naam:sub(i,i) == '-' then
				r[#r+1] = '_'
			else
				r[#r+1] = naam:sub(i,i)
			end
		end
		return table.concat(r)
	else
		return naam
	end
end

function tofunc(naar,van,t)
	t[#t+1] = 'function ('
	t[#t+1] = van
	t[#t+1] = ')\n {'

	t[#t+1] = 'return '
	tojs(naar, t)
	t[#t+1] = '\n'
	t[#t+1] = '}'
	t[#t+1] = '\n'
end

function tojs(exp,t)
	t = t or {}
	if atom(exp) then
		t[#t+1] = vertaal[exp] or naam2js(exp) or exp
	elseif exp[1] == '->' then
		tofunc(exp[3], exp[2], t)
	elseif infix[exp[1]] and exp[3] then
		t[#t+1] = '('
		tojs(exp[2], t)
		t[#t+1] = exp[1]
		tojs(exp[3], t)
		t[#t+1] = ')'
	elseif exp[1] == '[]' then
		--[[
		t[#t+1] = '['
		for i=2,#exp do
			tojs(exp[i], t)
			if i ~= #exp then
				t[#t+1] = ', '
			end
		end
		t[#t+1] = ']'
		]]
		t[#t+1] = '[200,200]'
	else
		tojs(exp[1], t)
		t[#t+1] = ' '
		t[#t+1] = '('
		for i=2,#exp do
			tojs(exp[i], t)
			t[#t+1] = ', '
		end
		t[#t] = nil
		t[#t+1] = ')'
	end
	return t
end

function stat2js(stat,t,vars)
	t[#t+1] = '\t'
	t[#t+1] = naam2js(stat[2])
	t[#t+1] = ' = '
	tojs(stat[3],t)
	t[#t+1] = ';\n'
	vars[#vars+1] = stat[2]
end

function toJs(block)
	local t = {
[[
var index = function(a,b) {
	return a[b];
};
var som = function (a) {
	var som = 0
	for (var i = 0; i < a.length; i++) {
		som = som + a[i];
	}
	return som;
}

var key = new Array(128).fill(0);
window.onkeydown = function(e) { key[e.keyCode] = true; }
window.onkeyup = function(e) { key[e.keyCode] = false; }

var toetsRechts = new Array(600).fill(0);
var toetsLinks = new Array(600).fill(0);
var toetsOmhoog = new Array(600).fill(0);
var toetsOmlaag = new Array(600).fill(0);
]]}

	-- update
	local vars = {}
	t[#t+1] = 
[[
function step() {
	// update
	for (var i = 0; i < 600; i++) {
		toetsRechts[i] = toetsRechts[i+1];
		toetsLinks[i] = toetsLinks[i+1];
		toetsOmhoog[i] = toetsOmhoog[i+1];
		toetsOmlaag[i] = toetsOmlaag[i+1];
	}
	toetsRechts[599] = key[39] / 60;
	toetsLinks[599] = key[37] / 60;
	toetsOmhoog[599] = key[38] / 60;
	toetsOmlaag[599] = key[40] / 60;
	]]

	for i=1,#block do
		local stat = block[i]
		stat2js(stat,t,vars)
	end

	-- draw
	t[#t+1] = [[
	// schoonmaken
	ctx.clearRect(0, 0, canvas.width, canvas.height);

	// teken cirkel
	ctx.beginPath();
	ctx.arc(cirkel[0], cirkel[1], cirkel[2] || 50, 0, Math.PI*2, true);
	ctx.closePath();
	ctx.fillStyle = '#2D0';
	ctx.fill();
	]]

	--[[
	for i,var in ipairs(vars) do
		t[#t+1] = '\tlove.graphics.print('
		t[#t+1] = '"'..var..' = "..unlisp('
		t[#t+1] = naam2love(var)
		t[#t+1] = '), 10, ' .. i*16 .. ')\n'
	end
	]]

	t[#t+1] = [[
	window.requestAnimationFrame(step);
}	
window.requestAnimationFrame(step);
	]]

	return table.concat(t)
end
