require 'util'
require 'func'
require 'symbool'
require 'combineer'
require 'bieb'

local bieb = bieb()

local jsbiebbron = file('bieb/bieb.js')

local jsbieb = {}
for waarde, naam in jsbiebbron:gmatch('(var ([^ ]*) = .-\n)\n') do
	jsbieb[naam] = waarde
end

--[[
[]       -> []
[](...)  -> [...]
{}(1 2)  -> {1,2}
+(A B)   -> A + B
*(A B)   -> A * B
-(A)     -> - A

sin(A)   -> Math.sin(A)
vanaf(A 1)   -> A.splice(1)
]]
local immjs = {
	['[]'] = '[$ARGS]',
	['[]u'] = '$TARGS',
	['{}'] = 'new Set([$ARGS])',
	['|'] = '$1 || $2',
	['en'] = '$1 && $2',

	-- arit
	['map'] = '$1.map($2)',
	['vouw'] = '$1.slice(1).reduce((x,y) => $2([x,y]),$1[0])',
	['atoom'] = 'atoom$1',
	['%'] = '$1 / 100',
	['+i'] = '$1 + $2',
	['+d'] = '$1 + $2',
	['+'] = '$1 + $2',
	['-'] = '$1 - $2',
	['-i'] = '$1 - $2',
	['-d'] = '$1 - $2',
	['·'] = '$1 * $2',
	['·i'] = '$1 * $2',
	['·d'] = '$1 * $2',
	['/'] = '$1 / $2',
	['/i'] = '$1 / $2',
	['/d'] = '$1 / $2',
	['mod'] = '$1 % $2',
	['modi'] = '$1 % $2',
	['modd'] = '$1 % $2',
	['aselect'] = 'Math.random()*($2-$1) + $1',
	['^'] = 'Math.pow($1, $2)',
	['^i'] = 'Math.pow($1, $2)',
	['^d'] = 'Math.pow($1, $2)',
	['^f'] = 'function(res) { for (var i = 0; i < $2; i++) res = $1(res); return res; }',
	['sqrt'] = 'Math.sqrt($1)',

	-- cmp
	['>'] = '$1 > $2',
	['≥'] = '$1 >= $2',
	['='] = '$1 === $2',
	['≠'] = '$1 !=== $2',
	['≤'] = '$1 <= $2',
	['<'] = '$1 < $2',

	-- deduct
	['∧'] = '$1 && $2', 
	['∨'] = '$1 || $2', 
	['⇒'] = '$1 ? $2 : $3', 

	['sin'] = 'Math.sin($1)',
	['cos'] = 'Math.cos($1)',
	['tan'] = 'Math.tan($1)',
	['sincos'] = '[Math.sin($1), Math.cos($1)]',

	-- discreet
	['min'] = 'Math.min($1,$2)',
	['max'] = 'Math.max($1,$2)',
	['entier'] = 'Math.floor($1)',
	['int'] = 'Math.floor($1)',
	['intd'] = 'Math.floor($1)',
	['abs'] = 'Math.abs($1)',
	['absd'] = 'Math.abs($1)',
	['absi'] = 'Math.abs($1)',
	['sign'] = '($1 > 0 ? 1 : -1)',

	-- exp
	['log10'] = 'Math.log($1, 10)',
	['‖'] = '$1 + $2',--.concat($2)',
	['‖u'] = '$1 + $2',
	['cat'] = '$1.join($2)', -- TODO werkt dit?
	['mapuu'] = '(function() { var totaal = ""; for (int i = 0; i < $1.length; i++) { totaal += $2($1[i]); }; return totaal; })() ', -- TODO werkt dit?
	['catu'] = '$1.join($2)',

	-- lijst
	['#'] = '$1.length',
	['Σ'] = '$1.reduce((a,b) => a + b, 0)',
	['..'] = '$1 == $2 ? [] : ($1 <= $2 ? Array.from(new Array(Math.max(0,$2-$1)), (x,i) => $1 + i) : Array.from(new Array(Math.max(0,$1-$2)), (x,i) => $1 - 1 - i))',
	['_u'] = '$1[$2]',
	['_'] = 'Array.isArray($1) ? alert($1[$2]) || $1[$2] : $1($2)',
	['vanaf'] = '$1.slice($2, $1.length)',
	['×'] = '[].concat.apply([], $1.map(x => $2.map(y => [x, y])))',
	['∘'] = 'function (a) { return $2($1(a)); }',
	['_prevvar'] = '(function(a){return vars[a];})',
	['_var'] = [[ (function(a) {
			var varindex = a[0];
			var ass = a[1];
			var array = Array.from(ass);
			var ret = vars[varindex];
			for (var i = 0; i < array.length; i++) {
				if (array[i] != null) {
					ret = array[i];
				}
			}
			vars[varindex] = ret;
			return ret;
		})($1)
	]],
}

-- Shift-K

local immjs0 = {}
for k,v in pairs(immjs) do
	local multi = v:match('$2')
	if multi then
		v = v:gsub('$1', '_arg[0]')
		v = v:gsub('$2', '_arg[1]')
		v = v:gsub('$3', '_arg[2]')
		v = v:gsub('$4', '_arg[3]')
	else
		v = v:gsub('$1', '_arg')
	end
	v = 'function(_arg) { return ' .. v .. '; }'

	immjs0[k] = v
end

local immsym = {
	['_2'] = '(function(_fn, _nieuwArg) { _oudArg = _arg || null; _arg = _nieuwArg ; var res = _fn(_arg); _arg = _oudArg; return res; })',
	--['_'] = '(function(a) { return a[0](a[1]); })',

	-- func
	['map'] = '(function(a){if (!Array.isArray(a[0])) a[0] = [a[0]]; return a[0].map(a[1]);})',
	['filter'] = '(function(a){return a[0].filter(a[1]);})',
	['reduceer'] = '(function(a){return a[0].reduce(a[1]);})',

	['_var'] = [[ (function(a) {
			var varindex = a[0];
			var ass = a[1];
			var array = Array.from(ass);
			var ret = vars[varindex];
			for (var i = 0; i < array.length; i++) {
				if (array[i] != null) {
					ret = array[i];
				}
			}
			vars[varindex] = ret;
			return ret;
		})
	]],

	['_prevvar'] = '(function(a){return vars[a];})',

	-- discreet
	['min'] = 'Math.min',
	['max'] = 'Math.max',
	['entier'] = 'Math.floor',
	['int'] = 'Math.floor',
	['intd'] = 'Math.floor',
	['abs'] = 'Math.abs',
	['absd'] = 'Math.abs',
	['absi'] = 'Math.abs',
	['sign'] = '($1 > 0 ? 1 : -1)',
	
	-- LIB
	['getContext'] = '(function() {return uit.children[0].getContext("2d");})',
	--['getContext'] = 'uit.children[0].getContext("2d")',
	['consolelog'] = 'console.log',

	-- muis
	['getContext'] = '(function(a) { return uit.children[0].getContext("2d")})',
	['vierkant'] = '(function(x,y,z) {return (function(c){\n\t\tc.beginPath();\n\t\tc.rect(x * 72, 720 - ((y+z) * 72) - 1, z * 72, z * 72);\n\t\tc.fillStyle = "white";\n\t\tc.fill();\n\t\treturn c;}); }',
	['rechthoek'] = '(function(x,y,w,h) {return (function(c){\n\t\tc.beginPath();\n\t\tc.rect(x * 72, 720 - ((y+h) * 72) - 1, w * 72, h * 72);\n\t\tc.fillStyle = "white";\n\t\tc.fill();\n\t\treturn c;}); })',
	['cirkel'] = '(function(xyz) {return (function(c){\n\t\tc.beginPath();\n\t\tc.arc(xyz[0] * 72, 720 - (xyz[1] * 72) - 1, xyz[2] * 72, 0, Math.PI * 2);\n\t\tc.fillStyle = "white";\n\t\tc.fill();\n\t\treturn c;}); })',
	['label'] = '(function(xyz) {return (function(c){\n\t\tc.font = "48px Arial";\n\t\tc.fillStyle = "white";\n\t\tc.fillText(xyz[2], xyz[0] * 72, 720 - (xyz[1] * 72) - 1);\n\t\treturn c;}); })',
	['lijn'] = [[
	(function(_args) {return (function(c){
		var x1 = _args[0];
		var y1 = _args[1];
		var x2 = _args[2];
		var y2 = _args[3];
		x1 = x1 * 72;
		y1 = 720 - y1 * 72;
		x2 = x2 * 72;
		y2 = 720 - y2 * 72;
		c.lineWidth = 4;
		c.strokeStyle = "white";
		c.beginPath();
		c.moveTo(x1,y1);
		c.lineTo(x2,y2);
		c.stroke();
		return c;});
	})]],
	['tekst'] = '(function(t) { return Array.isArray(t) ? t.toSource() : t.toString();})',
	['clearCanvas'] = '(function(c) { c.clearRect(0,0,1280,720); return c; })',
	['setInnerHtml'] = [[(function (a) {
		var t = Array.isArray(a) ? a.toSource() : a.toString();
		if (html != t) {
			uit.innerHTML = t;
			html = t;
		}
		return uit.children[0];
	})]],
	['canvas'] = [[uit.getChilden()[0] ]],
	['requestAnimationFrame'] = [[(function f(t) {
		if (stop) {stop = false; uit.innerHTML = ''; return; };
		if (!isFinite(t))
			_G = t;
		_G();
		mouseLeftPressed = false;
		mouseLeftReleased = false;
		keySpacePressed = false;
		keySpaceReleased = false;
		mouseMoving = false;
		requestAnimationFrame(f);
		return true;
	})]],
	['herhaal'] = [[
	(function(f, x) {
		var a = x;
		while (1) {
			var b = f(a);
			if (b) {
				a = b;
			} else {
				break;
			}
		}
		return a;
	})
	]],

	['_arg'] = '_arg',
	looptijd = '(new Date().getTime() - start)/1000', 
	sin = 'Math.sin',
	cos = 'Math.cos',
	tan = 'Math.tan',
	niets = 'null',
	regMuis = [[(function(x)
		{
			init = false;

			uit.onmouseup = function(ev) {
				mouseLeftReleased = true;
				mouseLeft = false;
			};

			uit.onmousedown = function(ev) {
				mouseLeftPressed = true;
				mouseLeft = true;
			};

			var canvas = uit.children[0] || uit;
			var b = canvas.getBoundingClientRect();
			uit.onmousemove = function(ev)
			{
				mouseX = ((ev.clientX-b.left)/canvas.clientWidth*17.778).toFixed(3);
				mouseY = ((b.bottom - ev.clientY)/canvas.clientHeight*10).toFixed(3);
				mouseMoving = true;
			};

			// toetsenbord neer
			uit.onkeydown = function(ev) {
				if (!_keys[ev.keyCode])
					_keysPressed.add(ev.keyCode);
				_keys[ev.keyCode] = true;
				return (ev.keyCode >= 111);
			};

			// toetsenbord op
			uit.onkeyup = function(ev) {
				_keys[ev.keyCode] = false;
				_keysReleased.add(ev.keyCode);
				return false;
			};

			return uit;
		}
	)]],
	['getContext'] = 'function(a) { if (uit.children.length == 0) alert("geen canvas gevonden"); return uit.children[0].getContext("2d"); }',
	['consolelog'] = 'console.log($1)',

	-- toetsen
	--['toetsNeer']  = '!!_keys[$1]',
	['toetsNeerBegin']  = '!!_keysPressed.has($1)',
	['toetsNeerEind']  = '!!_keysReleased.has($1)',

	['_arg0'] = '_arg0',
	['_arg1'] = '_arg1',
	['_arg2'] = '_arg2',
	['_arg3'] = '_arg3',
	['_arg4'] = '_arg4',
	looptijd = '(new Date().getTime() - start)/1000', 
	sin = 'Math.sin',
	cos = 'Math.cos',
	tan = 'Math.tan',
	niets = 'null',
	ja = 'true',
	nee = 'false',
	['τi'] = 'Math.PI * 2',
	['pi'] = 'Math.PI',
	init = 'init',
	['muisX'] = 'mouseX',
	['muisY'] = 'mouseY',
	['muisPos'] = '[mouseX, mouseY]',
	['muisBeweegt'] = 'mouseMoving',
	['beige'] = '"#f5f5dc"',
	['bruin'] = '"#996633"',
	['muisKlik'] = 'mouseLeft',
	['muisKlikBegin'] = 'mouseLeftPressed',
	['muisKlikEind'] = 'mouseLeftReleased',
}

function genjs(app)
	local s = {}
	local t = {}
	local maakvar = maakvars()

	local function blokjs(blok, tabs)
		for i,stat in ipairs(blok.stats) do
			local naam, exp = stat.a[1], stat.a[2]
			local var = maakvar()
			local f = fn(exp)

			if isatoom(exp) and immsym[exp.v] then
				t[#t+1] = string.format('%s%s = %s;', tabs, naam.v, immsym[exp.v])

			-- inline js
			elseif immjs[fn(exp)] and isobj(exp.a) then
				local imm = immjs[fn(exp)]
				local f = fn(exp)
				local multi = imm:match('$2')
				local o = imm
				if multi then
					o = exp.a[1] and o:gsub('$1', immsym[exp.a[1].v] or exp.a[1].v) or o
					o = exp.a[2] and o:gsub('$2', immsym[exp.a[2].v] or exp.a[2].v) or o
					o = exp.a[3] and o:gsub('$3', immsym[exp.a[3].v] or exp.a[3].v) or o
					o = exp.a[4] and o:gsub('$4', immsym[exp.a[4].v] or exp.a[4].v) or o
				else
					if not exp.a.v then error(o) end
					o = o:gsub('$1', exp.a.v)
				end
				t[#t+1] = string.format('%s%s = %s;', tabs, naam.v, o)

			elseif isatoom(exp) and immjs0[exp.v] then
				t[#t+1] = string.format('%s%s = %s;', tabs, naam.v, immjs0[exp.v])
			elseif isatoom(exp) then
				t[#t+1] = string.format('%s%s = %s;', tabs, naam.v, exp.v)
			elseif isobj(exp) then
				local o = obj(exp)
				local fmt
				if o == ',' then
					fmt = '%s%s = ['.. table.concat(map(exp, function(e) return e.v end), ', ') .. '];'
				elseif o == '{}' then
					fmt = '%s%s = new Set(['.. table.concat(map(exp, function(e) return e.v end), ', ') .. ']);'
				elseif o == '[]' then
					fmt = 'alert("LIJST!"); %s%s = ['.. table.concat(map(exp, function(e) return e.v end), ', ') .. '];'
				elseif o == '[]u' then
					local const = true
					--for k,sub in subs(exp) do if tonumber(k) and not isatoom(sub) or not tonumber(sub.v) then const = false end end
					if const then
						local str = string.char(table.unpack(map(exp, function(sub) return tonumber(sub.v) end)))
						fmt = '%s%s = '.. string.format('%q',str) .. ';'
					else
						fmt = '%s%s = String.fromCodePoint('.. table.concat(map(exp, function(e) return e.v end), ', ') .. ');'
					end
				else
					error'OBJ'
				end
				t[#t+1] = string.format(fmt, tabs, naam.v)
			elseif immsym[f] then
				t[#t+1] = string.format('%s%s = (%s)(%s);', tabs, naam.v, immsym[f], arg(exp).v)
			elseif immjs0[f] then
				t[#t+1] = string.format('%s%s = (%s)(%s);', tabs, naam.v, immjs0[f], arg(exp).v)
			elseif false and immjs[f] then
				-- a = CMD(a, b)
				local cmd = immjs[f]
				cmd = a and cmd:gsub('$1', assert(immsym[a] or a)) or cmd
				cmd = b and cmd:gsub('$2', assert(immsym[b] or b)) or cmd
				cmd = c and cmd:gsub('$3', assert(immsym[c] or c)) or cmd
				cmd = d and cmd:gsub('$4', assert(immsym[d] or d)) or cmd
				cmd = cmd:gsub('$TARGS', function() return string.format('%q', table.concat(map(exp, function(e) if tonumber(e.v) then return string.char(tonumber(e.v)) else return '" + String.fromCharCode(' .. e.v .. ') + "' end end)))end)
				cmd = cmd:gsub('$ARGS', function() return table.concat(map(exp, function(e) return e.v end), ', ') end)
				cmd = cmd:gsub('$[0-9]', 'null')
				cmd:gmatch('%$', function(n) error('onbekende var: '..tostring(n)) end)
				--cmd = a and cmd:gsub('_X_', a) or cmd
				--cmd = b and cmd:gsub('_Y_', b) or cmd
				--cmd = c and cmd:gsub('_Z_', c) or cmd
				t[#t+1] = string.format('%s%s = %s;', tabs, naam.v, cmd)
			elseif immsym[exp.v] then
				t[#t+1] = string.format('%s%s = %s;', tabs, naam.v, immsym[exp.v])
			elseif bieb[f] then
				t[#t+1] = string.format('%s%s = %s(%s);', tabs, naam.v, f, table.concat(map(exp, function(a) return a.v end), ','))
			elseif true then -- TODO check lijst
				--print(f, f.ref)
				t[#t+1] = string.format('%s%s = %s(%s);', tabs, naam.v, f, table.concat(map(exp, function(a) return a.v end), ','))
			else
				t[#t+1] = string.format(tabs .. "throw 'onbekende functie: ' + " .. f .. ";")
			end
		end
	end


	-- ;(((
	local blokken = {}
	for blok in pairs(app.punten) do
		blokken[blok.naam.v] = blok
	end

	local function flow(blok, tabs)
		blokjs(blok, tabs)
		local epi = blok.epiloog
		if fn(epi) == 'ga' and #epi.a == 3 then
			t[#t+1] = string.format('%sif (%s) {', tabs, epi.a[1].v)
			local b = blokken[epi.a[2].v]
			flow(b, tabs..'  ')
			t[#t+1] = tabs .. '} else {'
			flow(blokken[epi.a[3].v], tabs..'  ')
			t[#t+1] = tabs .. '}'
			
			local phi = blokken[b.epiloog.a.v]
			if phi then
				flow(phi, tabs)
			end
			--flow(blokken[b.epiloog[1].v])
		elseif fn(epi) == 'ga' and isatoom(arg(epi)) then
			--flow(blokken[epi[1].v], tabs..'  ')
		elseif fn(epi) == 'ret' then
			t[#t+1] = string.format('%sreturn %s;', tabs, epi.a[1].v)
		elseif epi.v == 'stop' then
			-- niets
		else
			error('foute epiloog: '..combineer(epi))
		end
	end

	for blok in spairs(app.punten) do
		local naam = blok.naam.v
		if blok.naam.v:sub(1,2) == 'fn' then
			t[#t+1] = 'function '..naam..'(_arg) {'
			flow(blok, '  ')
			t[#t+1] = '}'
		end
	end
	table.insert(s, [[
start = new Date().getTime();
vars = {};
if (typeof(document) == "undefined") { document = {getElementById: (x) => ({children: [{getContext: (z) => {}}], getBoundingClientRect: (y) => ({left: 0, top: 0, width: 0, height: 0, x: 0, y: 0, bottom: 0, right: 0}) })}}
mouseLeft = false;
mouseLeftPressed = false;
mouseLeftReleased = false;
mouseX = 0;
mouseY = 0;
_keys = {};
_keysPressed = new Set();
_keysReleased = new Set();
init = true;
html = "";
uit = document.getElementById("uit"); uit.tabIndex = -1;
stop = false;
]])
	flow(app.start, '')

	return table.concat(s, '\n') .. '\n' .. table.concat(t, '\n')
end

if test then
	require 'bouw.codegen'
	require 'bouw.arch'
	require 'ontleed'
	require 'oplos'
	require 'vertaal'

	local function moetzijn(broncode, waarde)
		local icode,f = vertaal(broncode, "js")
		if not icode then
			print('javascript vertaalfouten')
			for i,fout in ipairs(f) do
				print(fout2ansi(fout))
			end
		end
		local js = genjs(icode)
		local res = doejs(js)

		assert(res == waarde, 'was '..res..' maar moest zijn '..waarde)
	end

	--moetzijn("uit = 1 + 1", '2')
end
