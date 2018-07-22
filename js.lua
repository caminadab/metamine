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
		t[#t+1] = '['
		for i=2,#exp do
			tojs(exp[i], t)
			if i ~= #exp then
				t[#t+1] = ', '
			end
		end
		t[#t+1] = ']'
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
	t[#t+1] = 'var '
	t[#t+1] = naam2js(stat[2])
	t[#t+1] = ' = '
	tojs(stat[3],t)
	t[#t+1] = ';\n'
	vars[#vars+1] = stat[2]
end

function toJs(block)
	local t = {
[[
var g = window;

g.init = function() {
	g.index = function(a,b) {
		return a[b];
	};
	g.som = function (a) {
		var som = 0
		for (var i = 0; i < a.length; i++) {
			som = som + a[i];
		}
		return som;
	}

	g.key = new Array(128).fill(0);
	window.onkeydown = function(e) { key[e.keyCode] = true; }
	window.onkeyup = function(e) { key[e.keyCode] = false; }

	g.toets_rechts = new Array(600).fill(0);
	g.toets_links = new Array(600).fill(0);
	g.toets_omhoog = new Array(600).fill(0);
	g.toets_omlaag = new Array(600).fill(0);
};
]]}

	-- update
	local vars = {}
	t[#t+1] = 
[[
g.step = function() {
	// update
	for (var i = 0; i < 600; i++) {
		toets_rechts[i] = toets_rechts[i+1];
		toets_links[i] = toets_links[i+1];
		toets_omhoog[i] = toets_omhoog[i+1];
		toets_omlaag[i] = toets_omlaag[i+1];
	}
	toets_rechts[599] = key[39] / 60;
	toets_links[599] = key[37] / 60;
	toets_omhoog[599] = key[38] / 60;
	toets_omlaag[599] = key[40] / 60;
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
};

var g = window;
if (typeof g.active === 'undefined') {
	g.init(g);
	g.active = true;

	function dostep() {
		g.active = true;
		g.step();
	}

	window.requestAnimationFrame(dostep);
}
]]

	return table.concat(t)
end
