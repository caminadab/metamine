require 'func'

local noops = {
	['append'] = '(x, y) => {x.push(y); return x;}',
	['prepend'] = '(x, y) => {x.unshift(y); return x;}',

	['eval'] = 'eval',

	['plet'] = [[args => {
		var res = [];
		var k = 0;
		for (var i = 0; i < args.length; i++)
			for (var j = 0; j < args[i].length; j++)
				res[k++] = args[i][j];
		return res;
	} ]],

	['canvas.fontsize'] = [[ (function(vorm, fontsize) {return (function(c){
  var font = fontsize * SCHAAL + 'px Arial';
  c.font = font;
  vorm(c);
  return c;});
 })]],

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
		pad = "res/" + pad;
		if (resCache[pad])
			return resCache[pad];

		resCache[pad] = "";

		fetch(pad)
			.then(x => x.text())
			.then(x => resCache[pad] = x);

		return "";
	} ]],
	['getal'] = 'parseFloat',
	['splits'] = [[ (a, b) => a.split(b) ]],

	['matrixbind'] = [[ (prog, name, val) => {
		var loc = gl.getUniformLocation(prog, name);
		gl.uniformMatrix4fv(loc, false, new Float32Array(val));
		return prog;
	} ]],

	['uniformbind'] = [[ (prog, name, val) => {
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

	['shaderprogram'] = [[ (vertShader, fragShader) => {
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
	
	['texturebind'] = [[ (shaderProgram, name, texture, index) => {
		gl.activeTexture(gl.TEXTURE0 + index);
		gl.bindTexture(gl.TEXTURE_2D, texture);
		var loc = gl.getUniformLocation(shaderProgram, name);
		gl.uniform1i(loc, index);
		return shaderProgram;
	}
	]],

	['cubemapbind'] = [[ (shaderProgram, name, texture, index) => {
		gl.activeTexture(gl.TEXTURE0 + index);
		gl.bindTexture(gl.TEXTURE_CUBE_MAP, texture);
		var loc = gl.getUniformLocation(shaderProgram, name);
		gl.uniform1i(loc, index);
		return shaderProgram;
	}
	]],

	['cubemap'] = [[ (urls, index) => {
		if (textureCache[urls[0] ] != null)  {
			//gl.activeTexture(gl.TEXTURE0 + index);
			//gl.bindTexture(gl.TEXTURE_CUBEMAP, tex);
			return textureCache[urls[0] ];
		}

		var tex = gl.createTexture();

		gl.activeTexture(gl.TEXTURE0 + index);
		gl.bindTexture(gl.TEXTURE_CUBE_MAP, tex);

		textureCache[urls[0] ] = tex;

		// single pixel before load
		const level = 0;
		const width = 1;
		const height = 1;
		const border = 0;
		const srcFormat = gl.RGBA;
		const internalFormat = gl.RGBA;
		const srcType = gl.UNSIGNED_BYTE;

		for (var i = 0; i < 6; i++) {
			var code = gl.getError();
			const pixel = new Uint8Array([Math.random()*256, Math.random()*256, Math.random()*256, 255]);
			gl.texImage2D(gl.TEXTURE_CUBE_MAP_POSITIVE_X + i, level, gl.RGBA,
									width, height, border, srcFormat, srcType,
									pixel);
			var code = gl.getError();
			if (code)
				throw "cubemap: OpenGL error " + code;
		}

		var images = [];
		var nog = 6;
		for (var i = 0; i < 6; i++) {
			(i => {
				images[i] = new Image();
				images[i].onload = (x => {
					// clear error
					var code0 = gl.getError();

					nog = nog - 1;

					//XXXgl.activeTexture(gl.TEXTURE0 + index);
					gl.bindTexture(gl.TEXTURE_CUBE_MAP, tex);
					//console.log('cubemap #' + i + ', ' + images[i]);

					// only max
					gl.texParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
					gl.texParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
					//gl.texParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR);

					//gl.texImage2D(gl.TEXTURE_CUBE_MAP_POSITIVE_X + i, level, gl.RGBA,
					//	srcFormat, srcType, images[i]);

					const pixel = new Uint8Array([Math.random()*256, Math.random()*256, Math.random()*256, 255]);
					gl.texImage2D(gl.TEXTURE_CUBE_MAP_POSITIVE_X + i, level, gl.RGBA,
									width, height, border, srcFormat, srcType,
									pixel);

					gl.texImage2D(gl.TEXTURE_CUBE_MAP_POSITIVE_X + i, level, gl.RGBA,
						srcFormat, srcType, images[i]);

					var code = gl.getError();
					if (code)
						throw "cubemap laad: OpenGL error " + code;

					if (nog == 0)
						gl.generateMipmap(gl.TEXTURE_CUBE_MAP);

					var code = gl.getError();
					if (code)
						throw "cubemap gen mipmap: OpenGL error " + code;

					return;
				});
				images[i].src = 'res/' + urls[i];
			})(i);

		}
		return tex;
	} ]],

	['texture'] = [[ (url, id) => {
		url = 'res/' + url;

		if (textureCache[url] != null)  {
			var tex = textureCache[url];
			gl.activeTexture(gl.TEXTURE0 + id);
			gl.bindTexture(gl.TEXTURE_2D, tex);
			var code0 = gl.getError();
			return tex;
		}

		var tex = gl.createTexture();
		gl.activeTexture(gl.TEXTURE0 + id);
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
		const pixel = new Uint8Array([Math.random()*256, Math.random()*256, Math.random()*256, 255]);  // opaque blue
		gl.texImage2D(gl.TEXTURE_2D, level, internalFormat,
									width, height, border, srcFormat, srcType,
									pixel);

		const image = new Image();
		image.onload = function() {
			var code0 = gl.getError();
			gl.activeTexture(gl.TEXTURE0 + id);
			gl.bindTexture(gl.TEXTURE_2D, tex);
			gl.texImage2D(gl.TEXTURE_2D, level, internalFormat,
										srcFormat, srcType, image);
			gl.generateMipmap(gl.TEXTURE_2D);

			var code = gl.getError();
			if (code)
				throw "texture laad: OpenGL error " + code;
		};
		image.src = url;
		return tex;
	} ]],

	['shaderbind'] = [[ (shaderProgram,name,vertex_buffer) => {

		gl.bindBuffer(gl.ARRAY_BUFFER, vertex_buffer);
		var coord = gl.getAttribLocation(shaderProgram, name);

		if (coord == -1)
			throw name + " not found in " + shaderProgram;

		//point an attribute to the currently bound VBO
		gl.vertexAttribPointer(coord, 3, gl.FLOAT, false, 0, 0);
		gl.enableVertexAttribArray(coord);

		return shaderProgram;
	} ]],

	['superrender'] = [[ (gl, tex, shaderProgram, num) => {
		if (!window.canvas) {
		 window.canvas = document.getElementById('uit').children[0];
		}

         /* Step1: Prepare the canvas and get WebGL context */

         /* Step 4: Associate the shader programs to buffer objects */

         /* Step5: Drawing the required object (triangle) */
				 gl.activeTexture(gl.TEXTURE0);
				 gl.bindTexture(gl.TEXTURE0, tex);
				 
				 /* Texture */
				 if (false && tex) {
					gl.activeTexture(gl.TEXTURE0);
					gl.bindTexture(gl.TEXTURE_2D, tex);
				}

         // Clear the canvas
         //gl.clearColor(0.5, 0.5, 0.5, 0.9);
         gl.enable(gl.DEPTH_TEST); 
         //gl.enable(gl.CULL_FACE); 
         //gl.clear(gl.COLOR_BUFFER_BIT);

         // Draw the triangle
         gl.drawArrays(gl.TRIANGLES, 0, num*3);

	return gl;
			 }
				]],

	['grabbel'] = 'x => [Math.floor(Math.random()*x.length)]',
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
		if (!Array.isArray(args))
			args = [args];
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



	-- niet goed
	['newindex2']  = '(lijst,index,val) => { lijst[ index ] = val; return lijst; }',
	['newindex'] = '(lijst,index,val) => { var t = []; for (var i = 0; i< lijst.length; i++) { if (i == index) t[i] = val; else t[i] = lijst[i]; } return t; }',
	['scherm.ververst'] = 'true',
	['canvas.drawImage'] = '(i,x,y) => (c => c.drawImage(x, SCHAAL*x, SCHAAL*(100-y)))',
	['herhaal2'] = [[x => {
	var value = x[0];
	var len = x[1];
  if (len == 0) return [];
  var a = [value];
  while (a.length * 2 <= len) a = a.concat(a);
  if (a.length < len) a = a.concat(a.slice(0, len - a.length));
  return a;
	}]],

	-- functioneel
	['rits'] = '(a, b) => {  var c = []; for (var i = 0; i < a.length; i++) { c[i] = [a[i], b[i]]; }; return c;}',
  ['rits1'] = '(a, b) => {  var c = []; for (var i = 0; i < a.length; i++) { c[i] = [a[i], b]; }; return c;}',
  ['rrits1'] = '(a, b) => {  var c = []; for (var i = 0; i < a.length; i++) { c[i] = [b, a[i]]; }; return c;}',
  --['map'] = '(a, b) => a.map(b)',
  ['map'] = '(a, b) => { var r = []; for (var i = 0; i < a.length; i++) r[i] = b(a[i]); return r;}',
	['lmap'] = '(a, b) => a.map(x => b[x])',
  ['map4'] = '(a, b) => a.map(x => b(x[0], x[1], x[2], x[3]))',
  ['filter'] = '(a, b) => a.filter(b)',
  ['filter4'] = '(a, b) => a.filter(x => b(x[0], x[1], x[2], x[3]))',
  ['vouw'] = '(a, b) => a.reduce(b)',
	['reduceer'] = '(i, l, f) => l.reduce(f, i)',
	['sincos'] = 'x => [Math.cos(x), Math.sin(x)]',
	['cossin'] = 'x => [Math.sin(x), Math.cos(x)]',
	['atan'] = 'Math.atan2',

	-- discreet
	['min'] = '(x, y) => Math.min(x, y)',
	['max'] = '(x, y) => Math.max(x, y)',
	['maxindex'] = [[x => {
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
	 ['jsonencodeer'] = 'x => { try { return JSON.stringify(x); } catch (e) {return e.message; }}',
	 ['jsondecodeer'] = 'x => { try { return JSON.parse(x); } catch (e) {return e.message; }}',
	 ['deel'] = '(x,y,z) => x.slice(y, z)',
	 ['vind'] = [[(lijst, doel, index) => {
		 var doel = JSON.stringify(doel);
		 for (var i = index || 0; i < lijst.length; i++) {
			if (JSON.stringify(lijst[i]) == doel)
				return i;
			return null;
		}]],
	 
	 ['vind'] = '(x,y) => x.indexOf(y)',
	 ['vanaf'] = '(x,y) => x.slice(y)',
	 ['tot'] = '(x,y) => x.slice(0, y)',
	 ['canvas.linewidth'] = [[ (lijn, linewidth) => {
	 return c => {
		c.lineWidth = linewidth * SCHAAL;
		lijn(c);
		return c;
	}
 }]],

	 ['verf'] = [[
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

	['rgb'] = '(r,g,b) => [r,g,b]',
	['sorteer'] = '(function(a){ return a[0].sort(function (c,d) { return a[1]([c, d]); }); })',
	['afrond.onder'] = 'Math.floor',
	['afrond']       = 'Math.round',
	['afrond.boven'] = 'Math.ceil',
	['willekeurig'] = '(x, y) => Math.random()*(y-x) + x',
	['int'] = 'Math.floor',
	['abs'] = 'Math.abs',
	['tekst'] = 'toString', --'x => (typeof(x)=="object" && x.has && "{"+[...x].toString()+"}") || JSON.stringify(x) || (x || "niets").toString()',
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

	['vierkant'] = [[ (a, b, c) => {
	var x,y,r;
	if (c) {
		r = c * SCHAAL;
		x = a * SCHAAL;
		y = (100 - b) * SCHAAL - r;
	} else {
		r = b * SCHAAL;
		x = a[0] * SCHAAL;
		y = (100 - a[1]) * SCHAAL - r;
	}

  return context => {
    context.fillRect(x,y,r,r);
    return context;
  }
  } ]],

	['alert'] = 'x => {if (!window.alertKlaar) {alert(x); alertKlaar = true; }}',

	['label'] = [[ (a, b, c) => {
	var x, y, t;
	if (c != null) {
		t = c
		x = a * SCHAAL;
		y = (100 - b) * SCHAAL;
	} else {
		t = b;
		x = a[0] * SCHAAL;
		y = (100 - a[1]) * SCHAAL;
	}
  return context => {
    context.fillText(t,x,y);
    return context;
  }
	} ]],

	['loadimage'] = [[ url => {
		url = "res/" + url;
		if (imgCache[url]) 
			return imgCache[url];
		var image = new Image();
		image.src = url;
		imgCache[url] = image;
		return image;
	}]],

	['afbeelding'] = [[ (a, b, c, d, e) => {
		var img, x, y, w, h;
		img = a;
		if (Array.isArray(b)) {
			x = b[0] * SCHAAL;
			y = (100 - b[1]) * SCHAAL;
			w = c ? c * SCHAAL : null;
			h = d ? d * SCHAAL : null;
		} else {
			x = b * SCHAAL;
			y = (100 - c) * SCHAAL;
			w = d ? d * SCHAAL : null;
			h = e ? e * SCHAAL : null;
		}
		return context => {
			context.drawImage(img, x, y, w, h);
			return context;
		}
	} ]],


	['rechthoek'] = [[ (a, b, c, d) => {
	var x, y, w, h;
	if (c == null) {
		x = a[0] * SCHAAL;
		y = (100 - a[1]) * SCHAAL;
		w = b[0] * SCHAAL - x;
		h = (100 - b[1]) * SCHAAL - y;
	} else {
		x = a * SCHAAL;
		y = (100 - b) * SCHAAL;
		w = c * SCHAAL - x;
		h = (100 - d) * SCHAAL - y;
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

	['cirkel'] = [[ (a, b, c) => {
		return ctx => {
			var x, y, r;
			if (c == null) {
				x = a[0] * SCHAAL;
				y = (100 - a[1]) * SCHAAL;
				r = b * SCHAAL;
			} else {
				x = a * SCHAAL;
				y = (100 - b) * SCHAAL;
				r = c * SCHAAL;
			}
			ctx.beginPath();
			ctx.arc(x, y, Math.max(r,0), 0, Math.PI * 2);
			ctx.fill();
			return ctx;
		};
	}]],

	['ovaal'] = [[ args => {
	var a = args[0];
	var b = args[1];
	var c = args[2];
	var d = args[3];
	var e = args[4];

	var x, y, w, h, r;
	if (Array.isArray(a)) {
		x = a[0] * SCHAAL;
		y = (100 - a[1]) * SCHAAL;
		w = b * SCHAAL;
		h = c * SCHAAL;
		t = d;
	} else {
		x = a * SCHAAL;
		y = (100 - b) * SCHAAL;
		w = c * SCHAAL;
		h = d * SCHAAL;
		t = e;
		//console.log("x="+x+",y="+y+",w="+w+",h="+h+",t="+t)
	}
  return c => {
    c.beginPath();
		c.ellipse(x,y,w,h,t,0,Math.PI*2);
		c.fill();
    return c;
  }
	} ]],


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
	['mod'] = '(x,y) => x < 0 ? (x % y + y) % y : x % y',
	--['mod'] = '(x,y) => x % y',

	['int'] = 'Math.floor',
	['sin'] = 'Math.sin',
	['cos'] = 'Math.cos',
	['tan'] = 'Math.tan',

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

	-- dynamic
	['eerste'] = '(typeof($1)=="function") ? $1(0) : $1[0]',
	['tweede'] = '(typeof($1)=="function") ? $1(1) : $1[1]',
	['derde'] = '(typeof($1)=="function") ? $1(2) : $1[2]',
	['vierde'] = '(typeof($1)=="function") ? $1(3) : $1[3]',
}

local unops = {
	['#'] = 'var $1 = $1.length',
	['²'] = 'var $1 = $1 * $1;',
	['³'] = 'var $1 = $1 * $1 * $1;',
	['index0'] = 'var $1 = $1[0];',
	['√'] = 'var $1 = Math.sqrt($1);',
	['%'] = 'var $1 = $1 / 100;',
	['¬'] = 'var $1 = ! $1;',
	['-v'] = 'var $1 = $1.map(x => -x);',
	['!'] = 'var $1 = num; for (var i = num - 1; i >= 1; i--) $1 *= i;',

	-- som
	['Σ'] = [[var sum = 0; for (var i = 0; i < $1.length; i++) sum = sum + $1[i]; $1 = sum;]],
	['⋀'] = [[var sum = true; for (var i = 0; i < $1.length; i++) sum = sum && $1[i]; $1 = sum;]],
	['⋁'] = [[var sum = false; for (var i = 0; i < $1.length; i++) sum = sum || $1[i]; $1 = sum;]],
	['|'] = 'for (var i = 0; i < $1.length; i++) if ($1[i] != null) { $1 = $1[i]; break; }',
	['-'] = 'var $1 = -$1;',
}

local binops2 = {
	['>f']  = 'var $1 = x => $1(x) > $2(x);',
	['>f1'] = 'var a = $1; var $1 = x => a(x) > $2;',
	['=f']  = 'var $1 = x => $1(x) == $2(x);',
	['=f1'] = '$1 = x => $1(x) == $2;',
	['+f']  = 'var a = $1; var b = $2; var $1 = x => a(x) + b(x);',
	['+f1'] = 'var a = $1; var $1 = x => a(x) + $2;',
	['·f']  = 'var a = $1; var b = $2; var $1 = x => a(x) * b(x);',
	['·f1'] = 'var a = $1; var $1 = x => a(x) * $2;',
	['/f']  = 'var a = $1; var b = $2; var $1 = x => a(x) / b(x);',
	['/f1'] = 'var a = $1; var $1 = x => a(x) / $2;',

	['||='] = '$1.push($2);',
	['^l'] = [[var res = [];
	var k = 0;
	for (var i = 0; i < $2; i++)
		for (var j = 0; j < $1.length; j++)
			res[k++] = $1[j];
	$1 = res;]],

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

	['..'] = [[var r = [];
var k = 0;
for (var i = $1; i < $2; i++)
  r[k++] = i;
$1 = r;]],

	-- cart
	['×'] = [[
var r = [];
for (var j = 0; j < $2.length; j++)
	for (var i = 0; i < $1.length; i++)
		r.push([$1[i],$2[j] ]);
$1 = r; ]],

	-- cart tuple
	['×t'] = [[
var r = [];
for (var j = 0; j < $2.length; j++) {
	for (var i = 0; i < $1.length; i++) {
		var a = $1[i].slice();
		a.push($2[j]);
		r.push(a);
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
	['-f'] = 'x => -$1(x)',
	['/v1'] = '$1.map(x => x / $2)',
	['call'] = '$1($2)',
	['callm'] = '$1($2[0], $2[1], $2[2], $2[3])',
	['call1'] = '$1($2)',
	['_fr'] = '$2($1)',
	['_t'] = '$1.charCodeAt($2)',
	['index'] = '$1[$2]',
	['_'] = 'typeof($1) == "function" ? ($2[1] ? $1($2[0], $2[1], $2[2], $2[3]) : $1($2)) : (typeof($1) == "string" ? $1.charCodeAt($2) : $1[$2])',
	['^r'] = '$1 ^ $2',
	['+'] = '$1 + $2',
	['·'] = '$1 * $2',
	['/'] = '$1 / $2',
	['^'] = '$1 ^ $2',
	['..2'] = '$1 == $2 ? [] : ($1 <= $2 ? Array.from(new Array(Math.max(0,Math.floor($2 - $1))), (x,i) => $1 + i) : Array.from(new Array(Math.max(0,Math.floor($1 - $2))), (x,i) => $1 - 1 - i))',

	-- componeer
	['∘'] = '((f,g) => (x,y,z,w) => g(f(x,y,z,w)))($1,$2)',
	['∘2'] = [[((f,g) => z => {
		var res = z;
		for (var i = 0; i < 2; i++) {
			if (Array.isArray(i==0?f:g))
				res = (i==0?f:g)[res];
			else
				res = (i==0?f:g)(res);
		};
		return res;
	})($1,$2) ]],


	['^'] = 'Math.pow($1, $2)',
	['^f'] = [[(function (f,n) {
		return function(x,y,z,w) {
			if (y != null) {
				var r = [x,y,z,w];
				for (var i = 0; i < n; i++)
					r = f(r[0], r[1], r[2], r[3]);
			} else {
				var r = x;
				for (var i = 0; i < n; i++)
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
	['=g'] = '$1 === $2',
	['≠g'] = '$1 != $2',
	['≤'] = '$1 <= $2',
	['<'] = '$1 < $2',

	-- deduct
	['∧'] = '$1 && $2', 
	['∨'] = '$1 || $2', 
	['⇒'] = '$1 && $2', 

	-- exp
	-- concatenate
	['‖'] = 'typeof($1) == "string" ? $1 + $2 : $1.concat($2)',
	['‖u'] = '$1 .. $2',
	['‖i'] = '(for i,v in ipairs(b) do a[#+1] = v)($1,$2)',
	['mapuu'] = '(function() { var totaal = ""; for (int i = 0; i < $1.length; i++) { totaal += $2($1[i]); }; return totaal; })() ', -- TODO werkt dit?
	['catu'] = '$1.join($2)',
}

function jsgen(sfc)

	local makevar = maakindices()
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
			local name = atom(arg(ins))
			assert(name, unlisp(ins))
			name = noops[name] or name
			L[#L+1] = string.format('%svar %s = %s;', tabs, varname(focus), name), focus

		elseif tonumber(atom(ins)) then
			L[#L+1] = tabs..'var '..varname(focus) .. " = " .. atom(ins) .. ';'
			focus = focus + 1

		elseif fn(ins) == '∘' then
			local funcs = arg(ins)
			L[#L+1] = tabs..string.format('function %s(x) {')
			for i, func in ipairs(funcs) do
				local name = varname(focus - i + 1)
				L[#L+1] = tabs..'  x = '..name
			end
			L[#L+1] = tabs..string.format('function %s(x) {')

		elseif unops[atom(ins)] then
			local name = varname(focus-1)
			local di = unops[atom(ins)]:gsub('$1', name)
			L[#L+1] = tabs..di

		elseif binops2[atom(ins)] then
			local namea = varname(focus-2)
			local nameb = varname(focus-1)
			local di = binops2[atom(ins)]:gsub('$1', namea):gsub('$2', nameb)
			L[#L+1] = tabs..di
			focus = focus - 1

		elseif fn(ins) == 'stargs' then
			local namea = varname(focus-4)
			local nameb = varname(focus-1)
			local index = 1 + tonumber(atom(arg(ins)))
			local a = 'arg'..varname(index)..'0'
			local b = 'arg'..varname(index)..'1'
			L[#L+1] = tabs..string.format('var %s = %s;', a, namea)
			L[#L+1] = tabs..string.format('var %s = %s;', b, nameb)


		-- call2
		elseif atom(ins) == 'call2' then
			local namef = varname(focus-3)
			local namea = varname(focus-2)
			local nameb = varname(focus-1)
			L[#L+1] = tabs..string.format('var %s = %s(%s, %s);', namef, namef, namea, nameb)
			focus = focus - 2
		elseif atom(ins) == 'call3' then
			local namef = varname(focus-4)
			local namea = varname(focus-3)
			local nameb = varname(focus-2)
			local namec = varname(focus-1)
			L[#L+1] = tabs..string.format('var %s = %s(%s, %s, %s);', namef, namef, namea, nameb, namec)
			focus = focus - 3
		elseif atom(ins) == 'call4' then
			local namef = varname(focus-5)
			local namea = varname(focus-4)
			local nameb = varname(focus-3)
			local namec = varname(focus-2)
			local named = varname(focus-1)
			L[#L+1] = tabs..string.format('var %s = %s(%s, %s, %s, %s);', namef, namef, namea, nameb, namec, named)
			focus = focus - 4


		-- coole lussen

		elseif atom(ins) == 'lus' then
			-- ok
			focus = focus + 0

		elseif atom(ins) == 'eindlus' then
			local namee = varname(focus-5)
			local named = varname(focus-4)
			local namec = varname(focus-3)
			local nameb = varname(focus-2)
			local namea = varname(focus-1)
			--L[#L+1] = string.format('%s%s = %s(%s, %s);', tabs, namec, namea, nameb, namec)
			L[#L+1] = string.format('%s%s = %s;', tabs, namee, namea)
			tabs = tabs:sub(3)
			L[#L+1] = tabs..'}'
			focus = focus - 4

		-- igen(10)
		elseif atom(ins) == 'igen' then
			focus = focus + 1
			local maxname = varname(focus-2)
			local indexname = varname(focus-1)
			local nieuwname = varname(focus+0)
			L[#L+1] = tabs..string.format("for (var %s = 0; %s < %s; %s++) {", indexname, indexname, maxname, indexname)
			tabs = tabs .. '  '
			--L[#L+1] = tabs..string.format("var %s = %s;", nieuwname, indexname)

		-- igeni(10, 1)
		elseif atom(ins) == 'igeni' then
			focus = focus + 1
			local minname = varname(focus-3)
			local maxname = varname(focus-2)
			local indexname = varname(focus-1)
			local nieuwname = varname(focus+0)
			L[#L+1] = tabs..string.format("for (var %s = %s; %s < %s; %s++) {", indexname, minname, indexname, maxname, indexname)
			tabs = tabs .. '  '
			--L[#L+1] = tabs..string.format("var %s = %s;", nieuwname, indexname)
			--focus = focus + 1

		elseif atom(ins) == 'ifilter' then
			local lijstname = varname(focus-2)
			local predname = varname(focus-1)
			L[#L+1] = tabs..string.format("if (!%s) ", predname)
			L[#L+1] = tabs..'  '..'continue;'
			focus = focus - 1

		elseif atom(ins) == 'llus' then
			focus = focus + 3 -- 1 eraf (n2m), 1 erbij (index)
			local maxname = varname(focus-4)
			local lijstname = varname(focus-3)
			local indexname = varname(focus-2)
			local modindex = varname(focus-1)
			L[#L+1] = tabs..string.format("var %s = [];", lijstname)
			L[#L+1] = tabs..string.format("for (var %s = 0; %s < %s; %s++) {", indexname, indexname, maxname, indexname)
			tabs = tabs .. '  '
			L[#L+1] = tabs..string.format("var %s = %s;", modindex, indexname)

		elseif atom(ins) == 'eindllus' then
			local ret = varname(focus-4)
			local lijst = varname(focus-3)
			local index = varname(focus-2)
			local val = varname(focus-1)
			L[#L+1] = tabs..string.format("%s[%s] = %s;", lijst, index, val)
			tabs = tabs:sub(3)
			L[#L+1] = tabs.."}"
			L[#L+1] = tabs..string.format("var %s = %s;", ret, lijst)
			focus = focus - 3

		elseif atom(ins) == 'slus' then
			focus = focus + 3 -- 1 eraf (n2m), 1 erbij (index)
			local maxname = varname(focus-4)
			local lijstname = varname(focus-3)
			local indexname = varname(focus-2)
			local modindex = varname(focus-1)
			L[#L+1] = tabs..string.format("var %s = 0;", lijstname)
			L[#L+1] = tabs..string.format("for (var %s = 0; %s < %s; %s++) {", indexname, indexname, maxname, indexname)
			tabs = tabs .. '  '
			L[#L+1] = tabs..string.format("var %s = %s;", modindex, indexname)

		elseif atom(ins) == 'eindslus' then
			local ret = varname(focus-4)
			local lijst = varname(focus-3)
			local index = varname(focus-2)
			local val = varname(focus-1)
			local add = varname(focus+0)
			L[#L+1] = tabs..string.format("%s += %s;", lijst, val)
			tabs = tabs:sub(3)
			L[#L+1] = tabs.."}"
			L[#L+1] = tabs..string.format("var %s = %s;", ret, lijst)
			focus = focus - 3

		elseif binops[atom(ins)] then
			local namea = varname(focus-2)
			local nameb = varname(focus-1)
			local di = binops[atom(ins)]:gsub('$1', namea):gsub('$2', nameb)
			L[#L+1] = tabs..string.format('var %s = %s;', namea, di)
			focus = focus - 1

		elseif atom(ins) == 'eind' then
			local namea = varname(focus-1)
			local nameb = varname(focus-2)
			L[#L+1] = tabs..'return '..namea..';'
			tabs = tabs:sub(3)
			L[#L+1] = tabs.."}"
			focus = focus - 1

		elseif atom(ins) == 'anders' then
			local name = varname(focus-1)
			L[#L+1] = tabs .. "tmp = " .. name .. ';'
			L[#L+1] = tabs:sub(3) .. '} else {'
			focus = focus - 1

		elseif atom(ins) == 'einddan' then
			local name = varname(focus-1)
			L[#L+1] = tabs .. "tmp = " .. name .. ';'
			tabs = tabs:sub(3)
			L[#L+1] = tabs.."}"
			L[#L+1] = tabs..'var ' .. name .. ' = tmp;'
			focus = focus

		-- libfuncties?
		elseif noops[atom(ins)] then
			L[#L+1] = tabs..'var '..varname(focus) .. " = " .. noops[atom(ins)] .. ';'
			focus = focus + 1

		elseif fn(ins) == 'set' then
			local set = {}
			local num = tonumber(atom(arg(ins)))
			local name = varname(focus - num)
			for i=1,num do
				set[i] = varname(i + focus - num - 1)
			end
			L[#L+1] = tabs..string.format("var %s = new Set([%s]);", name, table.concat(set, ","))
			focus = focus - num + 1

		elseif fn(ins) == 'tupel' or fn(ins) == 'lijst' then
			local tupel = {}
			local num = tonumber(atom(arg(ins)))
			local name = varname(focus - num)
			for i=1,num do
				tupel[i] = varname(i + focus - num - 1)
			end
			L[#L+1] = tabs..string.format("var %s = [%s];", name, table.concat(tupel, ","))
			focus = focus - num + 1

		elseif fn(ins) == 'string' then
			local text = {}
			local num = tonumber(atom(arg(ins)))
			local name = varname(focus - num)
			for i=1,num do
				text[i] = varname(i + focus - num - 1)
			end
			L[#L+1] = tabs..string.format("var %s = String.fromCharCode(%s);", name, table.concat(text,  ","))
			focus = focus - num + 1

		elseif fn(ins) == 'arg' then
			local index = 1 + tonumber(atom(arg(ins)))
			local b = 'arg'..varname(index)
			--local var = string.format('%s1 != null ? %s2 != null ? %s3 != null ? [%s0, %s1, %s2, %s3] : [%s0, %s1, %s2] : [%s0, %s1] : %s0',
			--	b, b, b, b, b, b, b, b, b, b, b, b, b)
			local var = b .. '0'
			local name = varname(focus)
			L[#L+1] = string.format('%svar %s = %s;', tabs, name, var)
			focus = focus + 1
		elseif fn(ins) == 'arg0' then
			local nameA = 'arg'..varname(1+tonumber(atom(arg(ins))))..'0'
			local name = varname(focus)
			L[#L+1] = tabs..'var '..name..' = '..nameA..';'
			focus = focus + 1
		elseif fn(ins) == 'arg1' then
			local nameB = 'arg'..varname(1+tonumber(atom(arg(ins))))..'1'
			local name = varname(focus)
			L[#L+1] = tabs..'var '..name..' = '..nameB..';'
			focus = focus + 1
		elseif fn(ins) == 'arg2' then
			local nameB = 'arg'..varname(1+tonumber(atom(arg(ins))))..'2'
			local name = varname(focus)
			L[#L+1] = tabs..'var '..name..' = '..nameB..';'
			focus = focus + 1
		elseif fn(ins) == 'arg3' then
			local nameB = 'arg'..varname(1+tonumber(atom(arg(ins))))..'3'
			local name = varname(focus)
			L[#L+1] = tabs..'var '..name..' = '..nameB..';'
			focus = focus + 1

		elseif fn(ins) == 'fn' then
			local name = varname(focus)
			--print('NAAMA', atom(arg(ins)))
			local nameA = 'arg'..varname(1+tonumber(atom(arg(ins))))..'0'
			local nameB = 'arg'..varname(1+tonumber(atom(arg(ins))))..'1'
			local nameC = 'arg'..varname(1+tonumber(atom(arg(ins))))..'2'
			local nameD = 'arg'..varname(1+tonumber(atom(arg(ins))))..'3'
			L[#L+1] = tabs..string.format("var %s = (%s, %s, %s, %s) => {", name, nameA, nameB, nameC, nameD)
			focus = focus + 1
			tabs = tabs..'  '

		elseif atom(ins) == 'dan' then
			focus = focus-1
			local name = varname(focus)
			L[#L+1] = tabs..string.format("if (%s) {", name)
			tabs = tabs..'  '

		elseif atom(ins) == 'kies' then
			local cond = varname(focus-3)
			local a = varname(focus-2)
			local b = varname(focus-1)
			local name = cond
			L[#L+1] = tabs..string.format("var %s = %s ? %s : %s;", name, cond, a, b)
			focus = focus - 2

		-- cache
		elseif fn(ins) == 'ld' then
			local name = varname(focus)
			local index = atom(arg(ins))
			L[#L+1] = string.format('%svar %s = cache[%s];', tabs, name, index)
			focus = focus + 1

		elseif fn(ins) == 'st' then
			local name = varname(focus-1)
			local index = atom(arg(ins))
			L[#L+1] = string.format('%scache[%s] = %s;', tabs, index, name)

		else
			error('onbekende instructie: '..unlisp(ins))

		end
		--L[#L+1] = 'print("'..L[#L]..'")'
		--L[#L+1] = 'print('..varname(focus)..')'
	end

	local function ins2js2(insA, insB)
		if unops[atom(insB)] then
			ins2js(insA)
			ins2js(insB)

		elseif binops2[atom(insB)] then
			ins2js(insA)
			ins2js(insB)

		elseif binops[atom(insB)] then
			local namea = varname(focus-1)
			local nameb = atom(insA)
			local di = binops[atom(insB)]:gsub('$1', namea):gsub('$2', nameb)
			L[#L+1] = tabs..string.format('var %s = %s;', namea, di)

		else
			ins2js(insA)
			ins2js(insB)
		end
	end

	L[#L+1] = 'cache = {};'

	local i = 1

	while i <= #sfc do
		if tonumber(atom(sfc[i])) and sfc[i+1] then
			ins2js2(sfc[i], sfc[i+1])
			i = i + 1
		else
			ins2js(sfc[i])
		end
		i = i + 1
	end

	L[#L+1] = 'return '..varname(focus-1)..';'

	return table.concat(L, '\n')
end
