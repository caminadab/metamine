require 'func'

local unops = {
	['#'] = '$1.length',
	['√'] = 'Math.sqrt($1)',
	['%'] = '$1 / 100;',
	['-'] = '- $1',
	['¬'] = '! $1',
	['-v'] = '$1.map(x => -x)',
	['!'] = [[(num => {
  if (num === 0 || num === 1)
    return 1;
  for (var i = num - 1; i >= 1; i--) {
    num *= i;
  }
  return num;})($1)
	]],
	['derdemachtswortel'] = 'Math.pow($1,1/3)',
}

local noops = {

	['eval'] = 'eval',

	['debugsom'] = [[x => {
		var s = 0;
		for (var i = 0; i < 1000000; i++)
			s += i;
		return s;
	}]],

	['plet'] = [[args => {
		var res = [];
		var k = 0;
		for (var i = 0; i < args.length; i++)
			for (var j = 0; j < args[i].length; j++)
				res[k++] = args[i][j];
		return res;
	} ]],
	['vertexshader'] = [[ code => {
		if (shaderCache[code]) 
			return shaderCache[code];
		var vertShader = gl.createShader(gl.VERTEX_SHADER);
		gl.shaderSource(vertShader, code);
		gl.compileShader(vertShader);
		shaderCache[code] = vertShader;
		var msg = gl.getShaderInfoLog(vertShader);
		if (gl.getError()) {
			var msg = gl.getShaderInfoLog(vertShader);
			throw msg;
		}
		return vertShader;
	} ]],

	['download'] = [[pad => {
		if (resCache[pad])
			return resCache[pad];

		resCache[pad] = "";

		fetch(pad)
			.then(x => x.text())
			.then(x => {resCache[pad] = x;});

		return "";
	} ]],
	['getal'] = 'parseFloat',
	['splits'] = [[ args => args[0].split(args[1]) ]],
	['splits2'] = [[ (a, b) => a.split(b) ]],
	['matrixbind'] = [[ args => {
		var prog = args[0];
		var name = args[1];
		var val = args[2];

		var loc = gl.getUniformLocation(prog, name);
		gl.uniformMatrix4fv(loc, false, new Float32Array(val));
		return prog;
	} ]],

	['uniformbind'] = [[ args => {
		var prog = args[0];
		var name = args[1];
		var val = args[2];

		var loc = gl.getUniformLocation(prog, name);
		if (Array.isArray(val)) {
			if (val.length == 2) gl.uniform2fv(loc, val);
			if (val.length == 3) gl.uniform3fv(loc, val);
			if (val.length == 4) gl.uniform4fv(loc, val);
		}
		else
			gl.uniform1f(loc, val);
		return prog;
	} ]],

	['fragmentshader'] = [[ code => {
		if (shaderCache[code])
			return shaderCache[code];
		var fragShader = gl.createShader(gl.FRAGMENT_SHADER);
		gl.shaderSource(fragShader, code);
		gl.compileShader(fragShader);
		if (gl.getError()) {
			var msg = gl.getShaderInfoLog(fragShader);
			throw msg;
		}
		shaderCache[code] = fragShader;
		return fragShader;
	} ]],

	['shaderprogram'] = [[ args => {
		var vertShader = args[0];
		var fragShader = args[1];
		var cached = programCache[vertShader + fragShader];
		if (cached)
			return cached;
		var shaderProgram = gl.createProgram();
		gl.attachShader(shaderProgram, vertShader); 
		gl.attachShader(shaderProgram, fragShader);

		// Link both programs
		gl.linkProgram(shaderProgram);
		gl.useProgram(shaderProgram);

		if ( !gl.getProgramParameter( shaderProgram, gl.LINK_STATUS) ) {
			var info = gl.getProgramInfoLog(shaderProgram);
			var shaderinfo1 = gl.getShaderInfoLog(vertShader);
			var shaderinfo2 = gl.getShaderInfoLog(fragShader);
			throw 'Could not compile WebGL program. \n\n' + info + '\n' + shaderinfo1 + '\n' + shaderinfo2;
		}

		programCache[vertShader + fragShader] = shaderProgram;
		return shaderProgram;
	}
	]],

	['vertexbuffer'] = [[ vertices => {
		var vertex_buffer = gl.createBuffer();

		// Bind an empty array buffer to it
		gl.bindBuffer(gl.ARRAY_BUFFER, vertex_buffer);
		gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(vertices), gl.STATIC_DRAW);
		return vertex_buffer;
	}]],
	
	['texturebind'] = [[ args => {
		var shaderProgram = args[0];
		var name = args[1];
		var texture = args[2];

		gl.activeTexture(gl.TEXTURE0);
		gl.bindTexture(gl.TEXTURE_2D, texture);
		var loc = gl.getUniformLocation(shaderProgram, name);
		gl.uniform1i(loc, 0);
		return shaderProgram;
	}
	]],

	['cubemapbind'] = [[ args => {
		var shaderProgram = args[0];
		var name = args[1];
		var texture = args[2];

		gl.activeTexture(gl.TEXTURE1);
		gl.bindTexture(gl.TEXTURE_CUBE_MAP, texture);
		var loc = gl.getUniformLocation(shaderProgram, name);
		gl.uniform1i(loc, 1);
		return shaderProgram;
	}
	]],

	['cubemap'] = [[ urls => {
		if (textureCache[urls[0] ]) 
			return textureCache[urls[0] ];

		var tex = gl.createTexture();

		gl.activeTexture(gl.TEXTURE1);
		gl.bindTexture(gl.TEXTURE_CUBE_MAP, tex);

		textureCache[urls[0] ] = tex;

		// single pixel before load
		const level = 0;
		const width = 1;
		const height = 1;
		const border = 0;
		const srcFormat = gl.RGBA;
		const srcType = gl.UNSIGNED_BYTE;

		for (var i = 0; i < 6; i++) {
			const pixel = new Uint8Array([i * (255/6), 0, 255, 255]);  // opaque blue
			gl.texImage2D(gl.TEXTURE_CUBE_MAP_POSITIVE_X + i, level, gl.RGBA,
									width, height, border, srcFormat, srcType,
									pixel);
		}

		var images = [];
		var nog = 6;
		for (var i = 0; i < 6; i++) {
			(i => {
				images[i] = new Image();
				images[i].onload = (x => {
					nog = nog - 1;
					gl.activeTexture(gl.TEXTURE1);
					gl.bindTexture(gl.TEXTURE_CUBE_MAP, tex);
					console.log(i + ', ' + images[i]);

					// only max
					//gl.texParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
					//gl.texParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
					//gl.texParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR);

					gl.texImage2D(gl.TEXTURE_CUBE_MAP_POSITIVE_X + i, level, gl.RGBA8, srcFormat, srcType, images[i]);

					if (nog == 0)
						gl.generateMipmap(gl.TEXTURE_CUBE_MAP);
					return;
				});
				images[i].src = urls[i];
			})(i);

		}
		return tex;
	} ]],

	['texture'] = [[ url => {
		if (textureCache[url])  {
			var tex = textureCache[url];
			gl.activeTexture(gl.TEXTURE0);
			gl.bindTexture(gl.TEXTURE_2D, tex);
			return tex;
		}

		var tex = gl.createTexture();
		gl.activeTexture(gl.TEXTURE0);
		gl.bindTexture(gl.TEXTURE_2D, tex);

		textureCache[url] = tex;

		// single pixel before load
		const level = 0;
		const internalFormat = gl.RGBA;
		const width = 1;
		const height = 1;
		const border = 0;
		const srcFormat = gl.RGBA;
		const srcType = gl.UNSIGNED_BYTE;
		const pixel = new Uint8Array([0, 0, 255, 255]);  // opaque blue
		gl.texImage2D(gl.TEXTURE_2D, level, internalFormat,
									width, height, border, srcFormat, srcType,
									pixel);

		const image = new Image();
		image.onload = function() {
			gl.activeTexture(gl.TEXTURE0);
			gl.bindTexture(gl.TEXTURE_2D, tex);
			gl.texImage2D(gl.TEXTURE_2D, level, internalFormat,
										srcFormat, srcType, image);
		 gl.generateMipmap(gl.TEXTURE_2D);
		};
		image.src = url;
		return tex;
	} ]],

	['shaderbind'] = [[ args => {
		var shaderProgram = args[0];
		var name = args[1];
		var vertex_buffer = args[2];

		gl.bindBuffer(gl.ARRAY_BUFFER, vertex_buffer);
		var coord = gl.getAttribLocation(shaderProgram, name);

		if (coord == -1) {
			throw name + " not found in " + shaderProgram;
		}

		//point an attribute to the currently bound VBO
		gl.vertexAttribPointer(coord, 3, gl.FLOAT, false, 0, 0);
		gl.enableVertexAttribArray(coord);

		return shaderProgram;
	} ]],

	['superrender'] = [[ args => {
		var gl = args[0];
		var tex = args[1];
		var shaderProgram = args[2];
		var num = args[3];

		if (!window.canvas) {
		 window.canvas = document.getElementById('uit').children[0];
		}

         /* Step1: Prepare the canvas and get WebGL context */

         /* Step 4: Associate the shader programs to buffer objects */

         /* Step5: Drawing the required object (triangle) */
				 
				 /* Texture */
				 if (tex) {
					gl.activeTexture(gl.TEXTURE0);
					gl.bindTexture(gl.TEXTURE_2D, tex);
				}

         // Clear the canvas
         //gl.clearColor(0.5, 0.5, 0.5, 0.9);
         gl.enable(gl.DEPTH_TEST); 
         //gl.clear(gl.COLOR_BUFFER_BIT);

         // Draw the triangle
         gl.drawArrays(gl.TRIANGLES, 0, num*3);

	return gl;
			 }
				]],
	['grabbel'] = 'x => x[Math.floor(Math.random()*x.length)]',
	['fn.nul'] = 'x => x(0)',
	['fn.een'] = 'x => x(1)',
	['fn.twee'] = 'x => x(2)',
	['fn.drie'] = 'x => x(3)',
	
	['fn.kruid'] = 'fx => y => (fx[0](fx[1], y))',
	['fn.kruidL'] = 'fx => y => (fx[0](y, fx[1]))',

	['l.eerste'] = 'x => x[0]',
	['l.tweede'] = 'x => x[1]',
	['l.derde'] = 'x => x[2]',
	['l.vierde'] = 'x => x[3]',

	-- hetzelde als boven
	['componeer'] = [[args => (x => {
		var res = x;
		for (var i = 0; i < args.length; i++) {
			if (Array.isArray(args[i]))
				res = args[i][res];
			else
				res = args[i](res);
		};
		return res;
	}) ]],

	['niets'] = 'null',
	['omdraai'] = 'x => typeof(x) == "string" ? x.split("").reverse().join("") : x.reverse()',
	['klok'] = 'x => { var begin = new Date().getTime(); x(); var eind = new Date().getTime(); return eind - begin; }',

	['voor'] = [[x => {
  var max     = x[0];
  var start   = x[1];
  var filter1 = x[2];
  var map     = x[3];
  var filter2 = x[4];
  var vouw    = x[5];
  var val     = null;

	if (Array.isArray(max)) {
		if (max.length == 4) {
			val = map([0,0,0,0]);
			for (var i = 0; i < max[0]; i++) {
				for (var j = 0; j < max[1]; j++) {
					for (var k = 0; k < max[2]; k++) {
						for (var l = 0; l < max[3]; l++) {
							var w = map([i, j, k, l]);
							val = vouw([val, w]);
						}
					}
				}
			}
		}

		else if (max.length == 3) {
			val = map([0,0,0]);
			for (var i = 0; i < max[0]; i++) {
				for (var j = 0; j < max[1]; j++) {
					for (var k = 0; k < max[2]; k++) {
						var w = map([i, j, k]);
						val = vouw([val, w]);
					}
				}
			}
		}

		else if (max.length == 2) {
			val = map([0,0]);
			for (var i = 0; i < max[0]; i++) {
				for (var j = 0; j < max[1]; j++) {
					var w = map([i, j]);
					val = vouw([val, w]);
				}
			}
		}

	} else {
		val = map(0);
		for (var i = 1; i < max; i++) {
			var w = map(i); //Array.isArray(map) ? map[i] : map(i);
			val = vouw([val, w]);
		}
		return val;
	}
	return val;
} ]],

	['lvoor'] = [[x => {
  var max  = x[0];
	var filter1 = x[1];
  var map = x[2];
  var filter2 = x[3];
  var val = [];
	var index = 0;
	if (Array.isArray(max)) {
		if (max.length == 4) {
			for (var i = 0; i < max[0]; i++) {
				for (var j = 0; j < max[1]; j++) {
					for (var k = 0; k < max[2]; k++) {
						for (var l = 0; l < max[3]; l++) {
							var w = map([i, j, k, l]);
							val[index++] = w;
						}
					}
				}
			}
		}

		else if (max.length == 3) {
			for (var i = 0; i < max[0]; i++) {
				for (var j = 0; j < max[1]; j++) {
					for (var k = 0; k < max[2]; k++) {
						if (filter1([i, j, k])) {
							var w = map([i, j, k]);
							val[index++] = w;
						}
					}
				}
			}
		}

		else if (max.length == 2) {
			for (var i = 0; i < max[0]; i++) {
				for (var j = 0; j < max[1]; j++) {
					if (filter1([i, j])) {
						var w = map([i, j]);
						val[index++] = w;
					}
				}
			}
		}
	} else {
		for (var I = 0; I < max; I++) {
			if (filter1(I)) {
				var w = map(I);
				if (filter2(w)) {
					val[index++] = w;
				}
			}
		}
	}
	return val;
}]],

	-- niet goed
	['kies'] = 'x => x[0] ? x[1] : x[2]',
	['misschien'] = 'Math.random() < 0.5',
	['newindex'] = 'x => {x[0][ x[1] ] = x[2]; return x[0]; }',
	['newindex2'] = 'x => { var t = []; for (var i = 0; i< x[0].length; i++) { if (i == x[1]) t[i] = x[2]; else t[i] = x[0][i]; } return t; }',
	['scherm.ververst'] = 'true',
	['canvas.drawImage'] = 'x => (c => c.drawImage(x[0], SCHAAL*x[1], SCHAAL*(100-x[2])))',
	['herhaal'] = [[x => {
	var value = x[0];
	var len = x[1];
  if (len == 0) return [];
  var a = [value];
  while (a.length * 2 <= len) a = a.concat(a);
  if (a.length < len) a = a.concat(a.slice(0, len - a.length));
  return a;
	}]],

	-- functioneel
	['zip'] = '(function(args){ var a = args[0]; var b = args[1]; var c = []; for (var i = 0; i < a.length; i++) { c[i] = [a[i], b[i]]; }; return c;})',
	['zip2'] = '(a, b) => { var c = []; for (var i = 0; i < a.length; i++) { c[i] = [a[i], b[i]]; }; return c; }',
  ['zip1'] = '(function(args){ var a = args[0]; var b = args[1]; var c = []; for (var i = 0; i < a.length; i++) { c[i] = [a[i], b]; }; return c;})',
  ['rzip1'] = '(function(args){ var a = args[0]; var b = args[1]; var c = []; for (var i = 0; i < a.length; i++) { c[i] = [b, a[i]]; }; return c;})',
  ['map'] = '(function(a){ if (Array.isArray(a[1])) return a[0].map(x => a[1][x]); else return a[0].map(a[1]); })',
  ['map2'] = '(a, b) => { if (Array.isArray(b)) return a.map(x => b[x]); else return a.map(b); }',
  ['filter'] = '(function(a){return a[0].filter(a[1]);})',
  ['filter2'] = '(a, b) => a.filter(b)',
  ['reduceer'] = '(function(a){return a[0].reduce(a[1]);})',
	['vouw'] = [[(function(lf) {
		var l=lf[0];
		if (l.length == 0)
			return false;
		var f=lf[1];
		var r=l[0] ;
		for (var i=1; i < l.length; i++)
			r = f([r, l[i] ]);
		return r;
	}) ]],

	['vouw2'] = [[(l, f) => {
		if (l.length == 0)
			return false;
		var r=l[0] ;
		for (var i=1; i < l.length; i++)
			r = f([r, l[i] ]);
		return r;
	}) ]],

	['vouw22'] = [[(l, f) => {
		if (l.length == 0)
			return false;
		var r=l[0] ;
		for (var i=1; i < l.length; i++)
			r = f(r, l[i] );
		return r;
	} ]],

	['sincos'] = 'x => [Math.cos(x), Math.sin(x)]',
	['cossin'] = 'x => [Math.sin(x), Math.cos(x)]',
	['atan'] = 'x => Math.atan2(x[0], x[1])',

	-- discreet
	['min'] = 'x => Math.min(x[0], x[1])',
	['max'] = 'x => Math.max(x[0], x[1])',
	['min2'] = 'Math.min',
	['max2'] = 'Math.max',
	['maxindexXXX'] = [[x => {
		var maxi = null;
		var max = - Infinity;
		for (var i = 0; i < x.length; i++) {
			if (x[i] > max) {
				maxi = i;
				max = x[i];
			}
		}
		return maxi;
	}]],

	-- webgl
	['gl.createShader'] = 'gl => gl.createShader',
	['gl.VertexShader'] = 'gl => gl.VERTEX_SHADER',
	['gl.FragmentShader'] = 'gl => gl.FRAGMENT_SHADER',
	['gl.ArrayBuffer'] = 'gl => gl.ARRAY_BUFFER',
	['gl.createBuffer'] = 'gl => gl.createBuffer',
	['gl.bindBuffer'] = 'args => (gl => {gl.bindBuffer(args[0], args[1]); return gl;})',
	['gl.bufferData'] = 'args => (gl => gl.bufferData(args[0], new Float32Array(args[1]), gl.STATIC_DRAW)',
	['gl.clearColor'] = 'args => (gl => {gl.clear(gl.COLOR_BUFFER_BIT); return gl.clearColor(args[0], args[1], args[2], args[3] || 1);})',
  ['gl.enable'] = 'gl => gl.enable',
	['gl.DepthTest'] = 'gl => gl.DEPTH_TEST',
	['gl.ColorBufferBit'] = 'gl => gl.COLOR_BUFFER_BIT',
	['gl.clear'] = 'gl => gl.clear(gl.COLOR_BUFFER_BIT)',
	['gl.viewport'] = '(x,y,w,h) => (gl => gl.viewport(x,y,w,h))',
	['gl.Triangles'] = 'gl => gl.TRIANGLES',

   ['gl.drawArrays'] = 'gl => ((At, Ai, An) => gl.drawArrays(At,Ai,An))',
   ['gl.drawTriangles'] = 'args => (gl => gl.drawArrays(gl.TRIANGLES, args[0], args[1]))',

	 ['vanaf'] = 'x => x[0].slice(x[1])',
	 ['vanaf2'] = '(x,y) => x.slice(y)',
	 ['tot'] = 'x => x[0].slice(0, x[1])',
	 ['tot2'] = '(x,y) => x.slice(0, y)',
	 ['canvas.fontsize'] = [[
 (function(_args) {return (function(c){
  var vorm = _args[0];
  var fontsize = _args[1] * SCHAAL;
  var font = fontsize+'px Arial';
  c.font = font;
  vorm(c);
  return c;});
 })]],

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
	c.fillStyle = 'white';
  c.strokeStyle = 'white';
  return c;});
 })]],

	 ['verf2'] = [[
 (vorm, kleur) => (c => {
  var r = kleur[0]*255;
  var g = kleur[1]*255;
  var b = kleur[2]*255;
  var style = 'rgb('+r+','+g+','+b+')';
  c.fillStyle = style;
  c.strokeStyle = style;
  vorm(c);
	c.fillStyle = 'white';
  c.strokeStyle = 'white';
  return c;
 })]],


	['rgb'] = [[ (function(_args) { return _args; }) ]],
	['sorteer'] = '(function(a){ return a[0].sort(function (c,d) { return a[1]([c, d]); }); })',
	['afrond.onder'] = 'Math.floor',
	['afrond']       = 'Math.round',
	['afrond.boven'] = 'Math.ceil',
	['willekeurig'] = 'x => Math.random()*(x[1]-x[0]) + x[0]',
	['int'] = 'Math.floor',
	['abs'] = 'Math.abs',
	['tekst'] = 'x => (typeof(x)=="object" && x.has && "{"+[...x].toString()+"}") || JSON.stringify(x) || (x || "niets").toString()',
	['polygoon'] = [[ args => {
		return context => {
			context.beginPath();
			for (var i = 0; i < args.length; i++) {
				var x = args[i][0] * SCHAAL;
				var y = (100 - args[i][1]) * SCHAAL;
				if (i == 0)
					context.moveTo(x, y);
				else
					context.lineTo(x, y);
			}
			context.closePath();
			context.fill();
			return context;
		};
	} ]],
	['vierkant'] = [[ args => {
	var x, y, r;
	if (args[2]) {
		r = args[2] * SCHAAL;
		x = args[0] * SCHAAL;
		y = (100 - args[1]) * SCHAAL - r;
	} else {
		r = args[1] * SCHAAL;
		x = args[0][0] * SCHAAL;
		y = (100 - args[0][1]) * SCHAAL - r;
	}
	if (!window.ASDF) {
		window.ASDF = true;
		alert(x + ', ' + y + ', ' + r);
	}

  return context => {
    context.fillRect(x,y,r,r);
    return context;
  }
  } ]],

	['alert'] = 'x => {if (!window.alertKlaar) {alert(x); alertKlaar = true; }}',

	['label'] = [[ args => {
	var x, y, t;
	if (args[2]) {
		t = args[2];
		x = args[0] * SCHAAL;
		y = (100 - args[1]) * SCHAAL;
	} else {
		t = args[1];
		x = args[0][0] * SCHAAL;
		y = (100 - args[0][1]) * SCHAAL;
	}

	//if (typeof t == "object)
//		t = [...t]
//	alert("t = " + typeof t);
  return context => {
    context.fillText(t,x,y);
    return context;
  }
	} ]],

	['rechthoek'] = [[ args => {
	var x, y, w, h;
	if (args.length == 2) {
		x = args[0][0] * SCHAAL;
		y = (100 - args[0][1]) * SCHAAL;
		w = args[1][0] * SCHAAL - x;
		h = (100 - args[1][1]) * SCHAAL - y;
	} else {
		x = args[0] * SCHAAL;
		y = (100 - args[1]) * SCHAAL;
		w = args[2] * SCHAAL - x;
		h = (100 - args[3]) * SCHAAL - y;
	}
  return context => {
    context.fillRect(x,y,w,h);
    return context;
  }
	} ]],

	['lijn'] = [[ args => {
  return context => {
		context.beginPath();
		for (var i = 0; i < args.length; i++) {
			var x = args[i][0] * SCHAAL;
			var y = (100 - args[i][1]) * SCHAAL;
			if (i == 0)
				context.moveTo(x,y);
			else
				context.lineTo(x,y);
		}
		context.stroke();
    return context;
  }
	} ]],

	['kubus'] = [[ args => {
	} ]],

	['cirkel'] = [[ args => {
		return (function(c){
			var x, y, r;
			if (args.length == 2) {
				x = args[0][0] * SCHAAL;
				y = (100 - args[0][1]) * SCHAAL;
				r = args[1] * SCHAAL;
			} else {
				x = args[0] * SCHAAL;
				y = (100 - args[1]) * SCHAAL;
				r = args[2] * SCHAAL;
			}
			c.beginPath();
			c.arc(x, y, Math.max(r,0), 0, Math.PI * 2);
			c.fill();
			return c;
		});
	}]],


	['boog'] = [[ args => {
		return (function(c){
			var x, y, r, a1, a2;
			if (args.length == 4) {
				x = args[0][0] * SCHAAL;
				y = (100 - args[0][1]) * SCHAAL;
				r = args[1] * SCHAAL;
				a1 = args[2];
				a2 = args[3];
			} else {
				x = args[0] * SCHAAL;
				y = (100 - args[1]) * SCHAAL;
				r = args[2] * SCHAAL;
				a1 = args[3];
				a2 = args[4];
			}
			c.beginPath();
			c.arc(x, y, r, a1, a2);
			c.fill();
			return c;
		});
	}]],

	['canvas.clear'] = '(function(c) { c.clearRect(0,0,1900,1200); return c; })',

	['sign'] = '$1 > 0 ? 1 : -1',
	['mod'] = 'x => x[0] % x[1]',
	['mod2'] = '(x,y) => x % y',

	['int'] = 'Math.floor',
	['sin'] = 'Math.sin',
	['cos'] = 'Math.cos',
	['tan'] = 'Math.tan',

	['fn.id'] = 'x => x',
	['fn.constant'] = 'x => y => x',
	['fn.merge'] = 'fns => (x => fns.map(fn => fn(x)))',
	['fn.plus'] = 'x => y => x + y',
	['fn.mul'] = 'x => y => x * y',
	['-'] = 'function(x) return -x end',
	['log10'] = 'math.log10',
	['⊤'] = 'true',
	['⊥'] = 'false',
	['∅'] = '{}',
	['τ'] = 'Math.PI * 2',
	['π'] = 'Math.PI',
	['_f'] = '$1($2)',

	-- dynamisch
	['eerste'] = '(typeof($1)=="function") ? $1(0) : $1[0]',
	['tweede'] = '(typeof($1)=="function") ? $1(1) : $1[1]',
	['derde'] = '(typeof($1)=="function") ? $1(2) : $1[2]',
	['vierde'] = '(typeof($1)=="function") ? $1(3) : $1[3]',
}

local unops2 = {
	['Σ'] = [[var sum = 0; for (var i = 0; i < $1.length; i++) sum = sum + $1[i]; $1 = sum;]],
	['|'] = 'for (var i = 0; i < $1.length; i++) if ($1[i] != null) { $1 = $1[i]; break; }',
}

local binops2 = {
	['+'] = '$1 += $2;',
	['·'] = '$1 *= $2;',
	['/'] = '$1 /= $2;',
	['·m'] = [[
var aNumRows = $1.length, aNumCols = $1[0].length,
		bNumRows = $2.length, bNumCols = $2[0].length,
		m = new Array(aNumRows);  // initialize array of rows
for (var r = 0; r < aNumRows; ++r) {
	m[r] = new Array(bNumCols); // initialize the current row
	for (var c = 0; c < bNumCols; ++c) {
		m[r][c] = 0;             // initialize the current cell
		for (var i = 0; i < aNumCols; ++i) {
			m[r][c] += $1[r][i] * $2[i][c];
		}
	}
}
$1 = m;]],
	['·mv'] = [[
var vec = new Array($2.length);
var w = $1.length
var h = $1[0].length;
for (var y = 0; y < h; y++) {
	vec[y] = 0;
	for (var x = 0; x < w; x++) {
		vec[y] += $1[x][y] * $2[x];
	}
}
$1 = vec;]],

	['..'] = [[var res = [];
for (var i = 0; i < $2 - $1; i++)
  res[i] = $1 + i;
$1 = res;]],

	-- cart
	['×'] = [[
var r = [];
for (var j = 0; j < $2.length; j++) {
	for (var i = 0; i < $1.length; i++) {
		if (Array.isArray($1[i])) {
			var a = $1[i].slice();
			a.push($2[j]);
			r.push(a);
		}
		else
			r.push([$1[i],$2[j] ]);
	}
}
$1 = r; ]],
}

local binops = {
	-- set
	['∈'] = 'Array.isArray($2) ? $2.includes($1) : $2.has($1)',
	['∩'] = 'new Set([...$1].filter(x => $2.has(x)))',
	['∪'] = 'new Set([...$1, ...$2])',
	['-s'] = 'new Set([...$1].filter(x => !$2.has(x)))',
	['\\'] = 'new Set([...$1].filter(x => !$2.has(x)))',
	['+v']  = '(x => {var r = []; for (var i = 0; i < $1.length; i++) r[i] = $1[i] + $2[i]; return r;})()',
	['+v1'] = '$1.map(x => x + $2)',
	['·v?']  = '(x => {var r = []; for (var i = 0; i < $1.length; i++) r.push($1[i] * $2[i]); return r;})()',
	-- dot
	['·v']  = '(x => {var r = 0; for (var i = 0; i < $1.length; i++) r += $1[i] * $2[i]; return r;})()',
	['·v1'] = '$1.map(x => x * $2)',
	['+f'] = '$1.map(x => x + $2)',
	['·f1'] = '$1.map(x => x + $2)',
	['/v1'] = '$1.map(x => x / $2)',
	['_f'] = '$1($2)',
	['_t'] = '$1.charCodeAt($2)',
	['_l'] = '$1[$2]',
	['_'] = 'typeof($1) == "function" ? $1($2) : (typeof($1) == "string" ? $1.charCodeAt($2) : $1[$2])',
	['^r'] = '$1 ^ $2',
	['+'] = '$1 + $2',
	['·'] = '$1 * $2',
	['/'] = '$1 / $2',
	['^'] = '$1 ^ $2',
	['..2'] = '$1 == $2 ? [] : ($1 <= $2 ? Array.from(new Array(Math.max(0,Math.floor($2 - $1))), (x,i) => $1 + i) : Array.from(new Array(Math.max(0,Math.floor($1 - $2))), (x,i) => $1 - 1 - i))',

	-- componeer
	['∘'] = [[(args => z => {
		var res = z;
		for (var i = 0; i < args.length; i++) {
			if (Array.isArray(args[i]))
				res = args[i][res];
			else
				res = args[i](res);
		};
		return res;
	})([$1,$2]) ]],


	['^'] = 'Math.pow($1, $2)',
	['^f'] = [[(function (f,n) {
		return function(x) {
			var r = x;
			for (var i = 0; i < n; i++) {
				r = f(r);
			}
			return r;
		}
	})($1,$2)]],

	-- cmp
	['>'] = '$1 > $2',
	['≥'] = '$1 >= $2',
	['='] = 'JSON.stringify($1) == JSON.stringify($2)',
	['≠'] = 'JSON.stringify($1) != JSON.stringify($2)',
	['≤'] = '$1 <= $2',
	['<'] = '$1 < $2',

	-- deduct
	['∧'] = '$1 && $2', 
	['∨'] = '$1 || $2', 
	['⇒'] = '$1 && $2', 

	-- exp
	-- concatenate
	['‖'] = [[typeof($1) == "string" ? $1 + $2 : $1.concat($2)]],
	['‖u'] = '$1 .. $2',
	['‖i'] = '(for i,v in ipairs(b) do a[#+1] = v)($1,$2)',
	['mapuu'] = '(function() { var totaal = ""; for (int i = 0; i < $1.length; i++) { totaal += $2($1[i]); }; return totaal; })() ', -- TODO werkt dit?
	['catu'] = '$1.join($2)',
}

function jsgen(sfc)

	local maakvar = maakindices()
	local L = {}
	if opt and opt.L then
		setmetatable(L, {__newindex = function (t,k,v) rawset(L, k, v); print(v); end })
	end
	local tabs = ''
	local focus = 1

	local function emit(fmt, ...)
		local args = {...}
		uit[#uit+1] = fmt:gsub('$(%d)', function(i) return args[tonumber(i)] end)
	end

	local function ins2js(ins)
		if fn(ins) == 'push' or fn(ins) == 'put' then
			if fn(ins) == 'push' then
				focus = focus + 1
			end
			local naam = atoom(arg(ins))
			assert(naam, unlisp(ins))
			naam = noops[naam] or naam
			L[#L+1] = string.format('%svar %s = %s;', tabs, varnaam(focus), naam), focus

		elseif tonumber(atoom(ins)) then
			L[#L+1] = tabs..'var '..varnaam(focus) .. " = " .. atoom(ins) .. ';'
			focus = focus + 1

		elseif fn(ins) == 'rep' then
			local res = {}
			local num = tonumber(atoom(arg(ins)))
			assert(num, unlisp(ins))
			for i = 1, num-1 do
				L[#L+1] = tabs..string.format('var %s = %s;', varnaam(focus+i), varnaam(focus))
				focus = focus + 1
			end

		elseif atoom(ins) == 'dup' then
			L[#L+1] = tabs..string.format('var %s = %s;', varnaam(focus), varnaam(focus-1))
			focus = focus + 1

		elseif fn(ins) == 'kp' then
			local num = tonumber(atoom(arg(ins)))
			L[#L+1] = tabs..string.format('var %s = %s;', varnaam(focus-num+1), varnaam(focus-1))
			focus = focus + 1


		elseif fn(ins) == '∘' then
			local funcs = arg(ins)
			L[#L+1] = tabs..string.format('function %s(x) {')
			for i, func in ipairs(funcs) do
				local naam = varnaam(focus - i + 1)
				L[#L+1] = tabs..'  x = '..naam
			end
			L[#L+1] = tabs..string.format('function %s(x) {')

		elseif fn(ins) == 'wissel' then
			local naama = varnaam(focus)
			local num = atoom(arg(ins))
			local naamb = varnaam(focus + num)
			L[#L+1] = tabs..string.format('var %s,%s = %s,%s;', naama, naamb, naamb, naama)

		elseif unops[atoom(ins)] then
			local naam = varnaam(focus-1)
			local di = unops[atoom(ins)]:gsub('$1', naam)
			L[#L+1] = tabs..string.format('var %s = %s;', naam, di)

		elseif unops2[atoom(ins)] then
			local naam = varnaam(focus-1)
			local di = unops2[atoom(ins)]:gsub('$1', naam)
			L[#L+1] = tabs..di

		elseif binops2[atoom(ins)] then
			local naama = varnaam(focus-2)
			local naamb = varnaam(focus-1)
			local di = binops2[atoom(ins)]:gsub('$1', naama):gsub('$2', naamb)
			L[#L+1] = tabs..di
			focus = focus - 1


		-- call2
		elseif atoom(ins) == '_f2' then
			local naamf = varnaam(focus-3)
			local naama = varnaam(focus-2)
			local naamb = varnaam(focus-1)
			L[#L+1] = tabs..string.format('var %s = %s(%s, %s);', naamf, naamf, naama, naamb)
			focus = focus - 2


		elseif binops[atoom(ins)] then
			local naama = varnaam(focus-2)
			local naamb = varnaam(focus-1)
			local di = binops[atoom(ins)]:gsub('$1', naama):gsub('$2', naamb)
			L[#L+1] = tabs..string.format('var %s = %s;', naama, di)
			focus = focus - 1

		elseif atoom(ins) == 'eind' then
			local naama = varnaam(focus-1)
			local naamb = varnaam(focus-2)
			L[#L+1] = tabs..'return '..naama..';'
			tabs = tabs:sub(3)
			L[#L+1] = tabs.."}"
			focus = focus - 1

		elseif atoom(ins) == 'einddan' then
			local naam = varnaam(focus-1)
			local tempnaam = 'tmp'
			L[#L+1] = tabs .. tempnaam .. " = " .. naam .. ';'
			tabs = tabs:sub(3)
			L[#L+1] = tabs.."} else tmp = null;"
			L[#L+1] = tabs..'var ' .. naam .. " = " .. tempnaam .. ';'
			focus = focus

		-- biebfuncties?
		elseif noops[atoom(ins)] then
			L[#L+1] = tabs..'var '..varnaam(focus) .. " = " .. noops[atoom(ins)] .. ';'
			focus = focus + 1

		elseif fn(ins) == 'set' then
			local set = {}
			local num = tonumber(atoom(arg(ins)))
			local naam = varnaam(focus - num)
			for i=1,num do
				set[i] = varnaam(i + focus - num - 1)
			end
			L[#L+1] = tabs..string.format("var %s = new Set([%s]);", naam, table.concat(set, ","))
			focus = focus - num + 1


		elseif fn(ins) == 'tupel' or fn(ins) == 'lijst' then
			local tupel = {}
			local num = tonumber(atoom(arg(ins)))
			local naam = varnaam(focus - num)
			for i=1,num do
				tupel[i] = varnaam(i + focus - num - 1)
			end
			L[#L+1] = tabs..string.format("var %s = [%s];", naam, table.concat(tupel, ","))
			focus = focus - num + 1

		elseif fn(ins) == 'string' then
			local text = {}
			local num = tonumber(atoom(arg(ins)))
			local naam = varnaam(focus - num)
			for i=1,num do
				text[i] = varnaam(i + focus - num - 1)
			end
			L[#L+1] = tabs..string.format("var %s = String.fromCharCode(%s);", naam, table.concat(text,  ","))
			focus = focus - num + 1

		elseif fn(ins) == 'arg' then
			local var = varnaam(1+tonumber(atoom(arg(ins))))
			local naam = varnaam(focus)
			L[#L+1] = tabs..'var '..naam..' = arg'..var..';'
			focus = focus + 1

		elseif fn(ins) == 'fn' then
			local naam = varnaam(focus)
			local var = varnaam(1+tonumber(atoom(arg(ins))))
			L[#L+1] = tabs..string.format("var %s = (%s) => {", naam, "arg"..var)
			focus = focus + 1
			tabs = tabs..'  '

		elseif atoom(ins) == 'dan' then
			focus = focus-1
			local naam = varnaam(focus)
			L[#L+1] = tabs..string.format("if (%s) {", naam)
			tabs = tabs..'  '

		-- cache
		elseif fn(ins) == 'ld' then
			local naam = varnaam(focus)
			local index = atoom(arg(ins))
			L[#L+1] = string.format('%svar %s = cache[%s];', tabs, naam, index)
			focus = focus + 1

		elseif fn(ins) == 'st' then
			local naam = varnaam(focus-1)
			local index = atoom(arg(ins))
			L[#L+1] = string.format('%scache[%s] = %s;', tabs, index, naam)

		else
			error('onbekende instructie: '..unlisp(ins))

		end
		--L[#L+1] = 'print("'..L[#L]..'")'
		--L[#L+1] = 'print('..varnaam(focus)..')'
	end

	local function ins2js2(insA, insB)
		if unops[atoom(insB)] then
			ins2js(insA)
			ins2js(insB)
			--local naam = atoom(insA)
			--local di = unops[atoom(insB)]:gsub('$1', naam)
			--L[#L+1] = tabs..string.format('var %s = %s;', naam, di)
			--focus = focus - 1

		elseif binops2[atoom(insB)] then
			ins2js(insA)
			ins2js(insB)
			--local naama = varnaam(focus-1)
			--local naamb = atoom(insA)
			--local di = binops2[atoom(insB)]:gsub('$1', naama):gsub('$2', naamb)
			--L[#L+1] = tabs..di

		elseif binops[atoom(insB)] then
			local naama = varnaam(focus-1)
			local naamb = atoom(insA)
			local di = binops[atoom(insB)]:gsub('$1', naama):gsub('$2', naamb)
			L[#L+1] = tabs..string.format('var %s = %s;', naama, di)

		else
			ins2js(insA)
			ins2js(insB)
		end
	end

	L[#L+1] = 'cache = {};'

	local i = 1

	while i <= #sfc do
		if true and tonumber(atoom(sfc[i])) and sfc[i+1] then
			ins2js2(sfc[i], sfc[i+1])
			i = i + 1
		else
			ins2js(sfc[i])
		end
		i = i + 1
	end

	L[#L+1] = 'return '..varnaam(focus-1)..';'

	return table.concat(L, '\n')
end
