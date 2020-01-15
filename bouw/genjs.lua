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
	['niets'] = 'undefined',
	['dt'] = 'dt',
	['[]'] = '[$ARGS]',
	['[]u'] = '$TARGS',
	['{}'] = 'new Set([$ARGS])',

	-- arit
	--['sorteer'] = '$1.sort($2)',
	['misschien'] = 'Math.random() < 0.5',
	['map'] = '$1.map($2)',
	['vouw'] = '$1.length == 0 ? (x => x) : $1.length == 1 ? $1[0] : $1.slice(1).reduce((x,y) => $2([x,y]),$1[0])',
	['atoom'] = 'atoom$1',
	['%'] = '$1 / 100',
	['+i'] = '$1 + $2',
	['+d'] = '$1 + $2',
	['+'] = '$1 + $2',

	['¬'] = '! $1',
	['-'] = '- $1',
	['-i'] = '- $2',
	['-d'] = '- $2',
	['·'] = '$1 * $2',
	['·i'] = '$1 * $2',
	['·d'] = '$1 * $2',
	['/'] = '$1 / $2',
	['/i'] = '$1 / $2',
	['/d'] = '$1 / $2',
	['mod'] = '$1 % $2',
	['modi'] = '$1 % $2',
	['modd'] = '$1 % $2',
	['random.bereik'] = 'Math.random()*($2-$1) + $1', -- randomRange[0, 10]
	['√'] = 'Math.pow($1, 0.5)',
	['^'] = 'Math.pow($1, $2)',
	['^i'] = 'Math.pow($1, $2)',
	['^d'] = 'Math.pow($1, $2)',
	['^f'] = 'function(res) { for (var i = 0; i < $2; i++) res = $1(res); return res; }',
	['wortel'] = 'Math.sqrt($1)',
	['derdemachtswortel'] = 'Math.pow($1,1/3)',

	-- cmp
	['>'] = '$1 > $2',
	['≥'] = '$1 >= $2',
	['='] = '$1 === $2',
	['≠'] = '$1 !== $2',
	['≤'] = '$1 <= $2',
	['<'] = '$1 < $2',

	-- deduct
	['∧'] = '$1 && $2', 
	['∨'] = '$1 || $2', 
	['⇒'] = '$1 ? $2 : $3', 

	['sin'] = 'Math.sin($1)',
	['cos'] = 'Math.cos($1)',
	['tan'] = 'Math.tan($1)',
	['sincos'] = '[Math.cos($1), Math.sin($1)]',
	['cossin'] = '[Math.sin($1), Math.cos($1)]',

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
	-- concatenate
	['‖'] = 'Array.isArray($1) ? $1.concat($2) : $1 + $2',
	['‖u'] = '$1 + $2',
	['mapuu'] = '(function() { var totaal = ""; for (int i = 0; i < $1.length; i++) { totaal += $2($1[i]); }; return totaal; })() ', -- TODO werkt dit?
	['catu'] = '$1.join($2)',

	-- lijst
	['#'] = '$1.length',
	['Σ'] = '$1.reduce((a,b) => a + b, 0)',
	['..'] = '$1 == $2 ? [] : ($1 <= $2 ? Array.from(new Array(Math.max(0,Math.floor($2-$1))), (x,i) => $1 + i) : Array.from(new Array(Math.max(0,Math.floor($1-$2))), (x,i) => $1 - 1 - i))',
	['_u'] = '$1[$2]',
	['_'] = 'Array.isArray($1) ? index($1,$2) : typeof $1 == "string" ? $1[$2] : $1($2)',
	['vanaf'] = '$1.slice($2, $1.length)',

	['×'] = '[].concat.apply([], $1.map(x => $2.map(y => Array.isArray(x) ? Array.from(x).concat([y]) : [x, y])))', -- cartesisch product

	['∘'] = 'function (a) { return $2($1(a)); }',
	['_var'] = [[ (function(a) {
			var varindex = a[0];
			var ass = a[1];
			var array = Array.from(ass);
			var ret = vars[varindex];
			for (var i = 0; i < array.length; i++) {
				if (array[i] !== undefined) {
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
for k,v in spairs(immjs) do
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
	['cat'] = [[(function(lijst) {
	var s = [];
	for (var i = 0; i < lijst.length; i++)
		for (var j = 0; j < lijst[i].length; j++)
			s.push(lijst[i][j]);
	return s;
})]],
	['niets'] = 'undefined',
	['misschien'] = 'Math.random() < 0.5',
	['dt'] = 'dt',
	['_2'] = '(function(_fn, _nieuwArg) { alert("ok"); _oudArg = _arg || undefined; _arg = _nieuwArg ; var res = _fn(_arg); _arg = _oudArg; return res; })',
	--['_'] = '(function(a) { return a[0](a[1]); })',
	['|'] = [[ (function(conds) {
		const it = conds.entries();
		for (let entry of it) {
			if (entry[1] !== undefined && entry[1] !== false) {
				return entry[1];
			}
		}
		//alert("Lege waarde");
		//throw new Exception(":(");
		return undefined;
	}) ]],

	-- func
	['sorteer'] = '(function(a){ return a[0].sort(function (c,d) { return a[1]([c, d]); }); })',
	['zip'] = '(function(args){ var a = args[0]; var b = args[1]; var c = []; for (var i = 0; i < a.length; i++) { c[i] = [a[i], b[i]]; }; return c;})',
	['zip1'] = '(function(args){ var a = args[0]; var b = args[1]; var c = []; for (var i = 0; i < a.length; i++) { c[i] = [a[i], b]; }; return c;})',
	['rzip1'] = '(function(args){ var a = args[0]; var b = args[1]; var c = []; for (var i = 0; i < b.length; i++) { c[i] = [a, b[i]]; }; return c;})',
	['map'] = '(function(a){ if (Array.isArray(a[1])) return a[0].map(x => a[1][x]); else return a[0].map(a[1]); })',
	['filter'] = '(function(a){return a[0].filter(a[1]);})',
	['reduceer'] = '(function(a){return a[0].reduce(a[1]);})',

	['_prevvar'] = '(function(a){return vars[a];})',
	['_var'] = [[ (function(a) {
			var varindex = a[0];
			var ass = a[1];
			var array = ass;
			var ret = vars[varindex];
			if (!lastUpdated[varindex] || runtime > lastUpdated[varindex]) {
				for (var i = 0; i < array.length; i++) {
					if (array[i] !== undefined) {
						ret = array[i];
						break;
					}
				}
			}
			lastUpdated[varindex] = runtime;
			vars[varindex] = ret;
			return ret;
		})
	]],

	-- discreet
	['min'] = '(function(a) { return Math.min(a[0], a[1]); })',
	['max'] = '(function(a) { return Math.max(a[0], a[1]); })',
	['entier'] = 'Math.floor',
	['int'] = 'Math.floor',
	['abs'] = 'Math.abs',
	['sign'] = '($1 > 0 ? 1 : -1)',
	
	-- LIB
	['canvas.context2d'] = '(function() { var c = uit.children[0].getContext("2d"); c.fillStyle = "white"; c.strokeStyle = "white"; return c; })',
	['canvas.context3d'] = '(function() { if (uit.children.length > 0 && !window.gl) gl = uit.children[0].getContext("webgl"); return gl; })',

	['console.log'] = 'console.log',

	-- 3D

	-- model: positions & indices
	['model'] = [[(function(args) {
		if (!window.gl) { return; }


         /* Step2: Define the geometry and store it in buffer objects */

         var vertices = [-0.5, 0.5, -0.5, -0.5, 0.0, -0.5,];

         // Create a new buffer object
         var vertex_buffer = gl.createBuffer();

         // Bind an empty array buffer to it
         gl.bindBuffer(gl.ARRAY_BUFFER, vertex_buffer);
         
         // Pass the vertices data to the buffer
         gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(vertices), gl.STATIC_DRAW);

         // Unbind the buffer
         gl.bindBuffer(gl.ARRAY_BUFFER, null);

         /* Step3: Create and compile Shader programs */

         // Vertex shader source code
         var vertCode =
            'attribute vec2 coordinates;' + 
            'void main(void) {' + ' gl_Position = vec4(coordinates,0.0, 1.0);' + '}';

         //Create a vertex shader object
         var vertShader = gl.createShader(gl.VERTEX_SHADER);

         //Attach vertex shader source code
         gl.shaderSource(vertShader, vertCode);

         //Compile the vertex shader
         gl.compileShader(vertShader);

         //Fragment shader source code
         var fragCode = 'void main(void) {' + 'gl_FragColor = vec4(0.0, 0.0, 0.0, 0.1);' + '}';

         // Create fragment shader object
         var fragShader = gl.createShader(gl.FRAGMENT_SHADER);

         // Attach fragment shader source code
         gl.shaderSource(fragShader, fragCode);

         // Compile the fragment shader
         gl.compileShader(fragShader);

         // Create a shader program object to store combined shader program
         var shaderProgram = gl.createProgram();

         // Attach a vertex shader
         gl.attachShader(shaderProgram, vertShader); 
         
         // Attach a fragment shader
         gl.attachShader(shaderProgram, fragShader);

         // Link both programs
         gl.linkProgram(shaderProgram);

         // Use the combined shader program object
         gl.useProgram(shaderProgram);

         /* Step 4: Associate the shader programs to buffer objects */

         //Bind vertex buffer object
         gl.bindBuffer(gl.ARRAY_BUFFER, vertex_buffer);

         //Get the attribute location
         var coord = gl.getAttribLocation(shaderProgram, "coordinates");

         //point an attribute to the currently bound VBO
         gl.vertexAttribPointer(coord, 2, gl.FLOAT, false, 0, 0);

         //Enable the attribute
         gl.enableVertexAttribArray(coord);

		var f =  (function(_gl) {
		alert('OK!');

         /* Step5: Drawing the required object (triangle) */

         // Clear the canvas
         gl.clearColor(0.5, 0.5, 0.5, 0.9);

         // Enable the depth test
         gl.enable(gl.DEPTH_TEST); 
         
         // Clear the color buffer bit
         gl.clear(gl.COLOR_BUFFER_BIT);

         // Set the view port
         gl.viewport(0,0,1280,720);

         // Draw the triangle
         gl.drawArrays(gl.TRIANGLES, 0, 3);

				 return gl;
			});
		f(3);
		alert('ok');
		return f;

		/*var positions = new Float32Array(args[0]);
		var indices = new Int32Array(args[1]);

		if (!window.J) {
			window.J = true;
		}

    g_vbo = gl.createBuffer();
    g_elementVbo = gl.createBuffer();

		// punten
    gl.bindBuffer(gl.ARRAY_BUFFER, g_vbo);
    gl.bufferData(gl.ARRAY_BUFFER, positions.length * 4, gl.STATIC_DRAW);
    gl.bufferSubData(gl.ARRAY_BUFFER, 0, positions);

		// indices
    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, g_elementVbo);
    gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, indices.length * 4, gl.STATIC_DRAW);
		gl.bufferSubData(gl.ELEMENT_ARRAY_BUFFER, 0, indices);
    g_numElements = indices.length;

		gl.viewport(0, 0, 180, 100);
		gl.enable(gl.DEPTH_TEST);

		// errors
		var e = gl.getError();
		if (e != gl.NO_ERROR && e != gl.CONTEXT_LOST_WEBGL)
			uit.innerHTML = 'opengl error ' + e;
			gl.clearColor(1,1,0,1);
			gl.clear(gl.COLOR_BUFFER_BIT); //| gl.DEPTH_BUFFER_BIT);

		return (function(args) {
		});
			gl.clearColor(1,1,0,1);
			gl.clear(gl.COLOR_BUFFER_BIT); //| gl.DEPTH_BUFFER_BIT);
			gl.viewport(0, 0, 180, 100);

			// Bind and set up vertex streams
			gl.bindBuffer(gl.ARRAY_BUFFER, g_vbo);
			gl.vertexAttribPointer(0, 3, gl.FLOAT, false, 0, 0);
			gl.enableVertexAttribArray(0);
			gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, g_elementVbo);
			gl.enableVertexAttribArray(1);

			if (!window.A) {
				gl.drawElements(gl.TRIANGLES, g_numElements, gl.UNSIGNED_SHORT, 0);
				window.A = true;
			}

			// errors
			var e = gl.getError();
			if (e != gl.NO_ERROR && e != gl.CONTEXT_LOST_WEBGL)
				uit.innerHTML = 'opengl error ' + e;

			return gl;
		});
		*/

	})]],

	-- vormen
	['rechthoek'] = '(function(pos) {return (function(c){\n\t\tvar x = pos[0][0] + 17.778/2; var y = pos[0][1]; var w = pos[1][0] - x; var h = pos[1][1] - y;\n\t\tc.beginPath();\n\t\tc.rect(x * 7.2, 720 - ((y+h) * 7.2) - 1, w * 7.2, h * 7.2);\n\t\tc.fill();\n\t\treturn c;}); })',
	['cirkel'] = '(function(xyz) {return (function(c){\n\t\tvar x = xyz[0][0] || xyz[0]; var y = xyz[0][1] || xyz[1]; var r = xyz[0][0] ? xyz[1] : 1/xyz[2];\n\t\tc.beginPath();\n\t\tc.arc(x * 7.2, 720 - (y * 7.2) - 1, Math.max(r,0) * 7.2, 0, Math.PI * 2);\n\t\tc.fill();\n\t\treturn c;}); })',
	['boog'] = '(function(xyz) {return (function(c){\n\t\tvar x = xyz[0][0]; var y = xyz[0][1]; var r = xyz[1]; var a1 = xyz[2]; var a2 = xyz[3];\n\t\tc.beginPath();\n\t\tc.arc(x * 7.2, 720 - (y * 7.2) - 1, r * 7.2, a1, a2);\n\t\tc.fill();\n\t\treturn c;}); })',
	['label3'] = '(function(xyz) {return (function(c){\n\t\tc.font = "48px Arial";\n\t\tc.fillText(xyz[2], xyz[0] * 7.2, 720 - (xyz[1] * 7.2) - 1);\n\t\treturn c;}); })',
	['label2'] = '(function(xyz) {return (function(c){\n\t\tvar x = xyz[0][0]; var y = xyz[0][1]; var t = xyz[1];\n\t\tc.font = "48px Arial";\n\t\tc.fillText(t, x * 7.2, 720 - (y * 7.2) - 1);\n\t\treturn c;}); })',
	['vierkant'] = '(function(xyr) {return (function(c){\n\t\tvar x = xyr[0][0];\n\t\tvar y = xyr[0][1];\n\t\tvar d = xyr[1] || 1.0;\n\t\tc.beginPath();\n\t\tc.rect(x * 7.2, 720 - ((y+d) * 7.2) - 1, d * 7.2, d * 7.2);\n\t\tc.fill();\n\t\treturn c;}); })',
	['label'] = '(function(xyz) {return (function(c){\n\t\tvar x = xyz[0][0]; var y = xyz[0][1]; var t = xyz[1];\n\t\tc.font = "48px Arial";\n\t\tc.fillText(t, x * 7.2, 720 - (y * 7.2) - 1);\n\t\treturn c;}); })',
	['rechthoek'] = '(function(pos) {return (function(c){\n\t\tvar x = pos[0][0];\n\t\tvar y = pos[0][1];\n\t\tvar w = pos[1][0] - x;\n\t\tvar h = pos[1][1] - y;\n\t\tc.beginPath();\n\t\tc.rect(x * 7.2, 720 - ((y+h) * 7.2) - 1, w * 7.2, h * 7.2);\n\t\tc.fill();\n\t\treturn c;}); })',

	['verf'] = [[
	(function(_args) {return (function(c){
		var vorm = _args[0];
		var kleur = _args[1];
		var r = kleur[0]*255;
		var g = kleur[1]*255;
		var b = kleur[2]*255;
		var style = 'rgb('+r+','+g+','+b+')';
		c.fillStyle = style;
		c.strokeStyle = style;
		vorm(c);
		return c;});
	})]],

	['schaal'] = [[
	(function(_args){return (function(c){
		var vorm = _args[0];
		var grootte = _args[1];
	})})]],

	['rgb'] = [[ (function(_args) { return _args; }) ]],

	['lijn'] = [[
	(function(_args) {return (function(c){
		var x1 = _args[0][0];
		var y1 = _args[0][1];
		var x2 = _args[1][0];
		var y2 = _args[1][1];
		x1 = x1 * 7.2;
		y1 = 720 - y1 * 7.2;
		x2 = x2 * 7.2;
		y2 = 720 - y2 * 7.2;
		c.lineWidth = 4;
		c.beginPath();
		c.moveTo(x1,y1);
		c.lineTo(x2,y2);
		c.stroke();
		return c;});
	})]],
	['tekst'] = 'TEXT',
	['canvas.wis'] = '(function(c) { c.clearRect(0,0,1280,720); return c; })',
	['schrijf'] = [[(function (a) {
		var t = a == undefined ? "niets" : Array.isArray(a) ? a.toString() : a.toString();
		if (html != t) {
			uit.innerHTML = t;
			html = t;
		}
		return uit.children[0];
	})]],
	['herhaal.langzaam'] = [[(function f(t) {
		if (stop) {stop = false; uit.innerHTML = ''; return; };
		if (!isFinite(t))
		{
			dt = 0;
			_G = t;
		}
		else
		{
			now = t / 1000;
			if (prev)
			{
				dt = now - prev;
			}
			else
			{
				dt = 0;
			}
		}
		_G(0);
		mouseLeftPressed = false;
		mouseLeftReleased = false;
		_keysPressed.clear();
		_keysReleased.clear();
		mouseMoving = false;
		start = false;

		prev = now;
		runtime = now - starttime;
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
	sin = 'Math.sin',
	cos = 'Math.cos',
	tan = 'Math.tan',
	atan = '(function(a) { return Math.atan2(a[1], a[0]); })',
	niets = 'undefined',
	['invoer.registreer'] = [[(function()
		{
			if (!uit) return;

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
				mouseX = +((ev.clientX-b.left)/canvas.clientWidth*177.78).toFixed(3);
				mouseY = +((b.bottom - ev.clientY)/canvas.clientHeight*100).toFixed(3);
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
	['console.log'] = 'console.log($1)',

	-- toetsen
	['toets.neer']  = 'function(keyCode) { return !!_keys[keyCode]; }',
	['toets.neer.begin']  = 'function(keyCode) { return !!_keysPressed.has(keyCode); }',
	['toets.neer.eind']  = 'function(keyCode) { return !!_keysReleased.has(keyCode); }',

	['_arg0'] = '_arg0',
	['_arg1'] = '_arg1',
	['_arg2'] = '_arg2',
	['_arg3'] = '_arg3',
	['_arg4'] = '_arg4',
	sin = 'Math.sin',
	cos = 'Math.cos',
	tan = 'Math.tan',
	niets = 'undefined',
	['⊤'] = 'true',
	['⊥'] = 'false',
	['τ'] = 'Math.PI * 2',
	['π'] = 'Math.PI',
	['start'] = 'start',
	['scherm.ververst'] = '!start',

	['starttijd'] = 'starttime', 
	['looptijd'] = 'runtime', 
	['nu'] = 'now', 

	['muis.x'] = 'mouseX',
	['muis.y'] = 'mouseY',
	['muis.pos'] = '[mouseX, mouseY]',
	['muis.beweegt'] = 'mouseMoving',
	['beige'] = '"#f5f5dc"',
	['bruin'] = '"#996633"',
	['muis.klik'] = 'mouseLeft',
	['muis.klik.begin'] = 'mouseLeftPressed',
	['muis.klik.eind'] = 'mouseLeftReleased',
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
			elseif immjs[fn(exp)] and not (immjs[fn(exp)]:match('$2') and not exp.a[2]) then
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
					if not exp.a or not exp.a.v then error(o) end
					o = o:gsub('$1', exp.a.v)
				end
				if o:match('%$') then error('niet alle argumenten gevonden: '..o..', exp = '..e2s(exp)) end
				t[#t+1] = string.format('%s%s = %s;', tabs, naam.v, o)

			elseif isatoom(exp) and immjs0[exp.v] then
				t[#t+1] = string.format('%s%s = %s;', tabs, naam.v, immjs0[exp.v])
			elseif isatoom(exp) then
				t[#t+1] = string.format('%s%s = %s;', tabs, naam.v, exp.v)
			elseif isobj(exp) then
				local o = obj(exp)
				local fmt
				if o == ',' then
					--if not exp[1] then error(C(exp[2])) end
					--print(table.concat(map(exp, function(e) return e and e.v or 'alert("fout")' end), ','))
					fmt = '%s%s = ['.. table.concat(map(exp, function(e) return e.v or 'alert("fout")' end), ', ') .. '];'
				elseif o == '{}' then
					fmt = '%s%s = new Set(['.. table.concat(map(exp, function(e) return e.v end), ', ') .. ']);'
				elseif o == '[]' then
					fmt = '%s%s = ['.. table.concat(map(exp, function(e) return e.v end), ', ') .. '];'
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

	local function flow(blok, tabs)
		blokjs(blok, tabs)
		local epi = blok.epiloog

		if fn(epi) == 'ga' and #epi.a == 3 then
			t[#t+1] = string.format('%sif (%s) {', tabs, epi.a[1].v)
			local b = assert( app[epi.a[2].v], epi.a[2].v )
			flow(b, tabs..'  ')
			t[#t+1] = tabs .. '} else {'
			flow(app[epi.a[3].v], tabs..'  ')
			t[#t+1] = tabs .. '}'
			
			local phi = app[b.epiloog.a.v]
			if phi then
				flow(phi, tabs)
			end
			--flow(app[b.epiloog[1].v])
		elseif fn(epi) == 'ga' and isatoom(arg(epi)) then
			--flow(app[epi[1].v], tabs..'  ')
		elseif fn(epi) == 'ret' then
			t[#t+1] = string.format('%sreturn %s;', tabs, epi.a[1].v)
		elseif epi.v == 'stop' then
			-- niets
		else
			error('foute epiloog: '..combineer(epi))
		end
	end

	for naam, blok in spairs(app) do
		if blok.naam.v:sub(1,2) == 'fn' then
			t[#t+1] = 'function '..naam..'(_arg) {'
			flow(blok, '  ')
			t[#t+1] = '}'
		end
	end
	table.insert(s, [[
starttime = performance.now() / 1000;
start = true;
now = starttime;
runtime = 0;

vars = {};
lastUpdated = {}; // varindex -> double
if (typeof(document) == "undefined") { document = {getElementById: (x) => ({children: [{getContext: (z) => {}}], getBoundingClientRect: (y) => ({left: 0, top: 0, width: 0, height: 0, x: 0, y: 0, bottom: 0, right: 0}) })}}
mouseLeft = false;
mouseLeftPressed = false;
mouseLeftReleased = false;
mouseX = 0;
mouseY = 0;
_keys = {};
_keysPressed = new Set();
_keysReleased = new Set();
start = true;
dt = 0;
html = "";
uit = document.getElementById("uit");
stop = false;

function TEXT(t) {
	if (t === undefined)
		return "niets";
	if (t === true) return "ja";
	if (t === false) return "nee";

	if (Array.isArray(t)) {
		var r = "[";
		for (var i = 0; i < t.length; i++) {
			if (i > 0)
				r += ", ";
			r += TEXT(t[i]);
		}
		r += "]";
		return r;
	}

	return t.toString();
}

function index(lijst, indices) {
	if (Array.isArray(indices)) {
		var r = lijst;
		for (var i = 0; i < indices.length; i++) {
			r = r[ indices[i] ];
		}
		return r;
	} else {
		return lijst[Math.floor(indices)];
	}
}

]])
	--assert(app.start)
	flow(app.init, '')

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
