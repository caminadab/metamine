
function shaderProgram(args) {
	var gl = args[0];
	var vertCode = args[1][0];
	var fragCode = args[1][1];

         var vertCode =
            'attribute vec2 coordinates;' + 
            'void main(void) {' + ' gl_Position = vec4(coordinates,0.0, 1.0);' + '}';

         //Create a vertex shader object
         var vertShader = gl.createShader(gl.VERTEX_SHADER);
         gl.shaderSource(vertShader, vertCode);
         gl.compileShader(vertShader);

         //Fragment shader source code
         var fragCode = 'void main(void) {' + 'gl_FragColor = vec4(0.0, 0.0, 0.0, 0.1);' + '}';

         var fragShader = gl.createShader(gl.FRAGMENT_SHADER);
         gl.shaderSource(fragShader, fragCode);
         gl.compileShader(fragShader);

         // Create a shader program object to store combined shader program
         var shaderProgram = gl.createProgram();

         gl.attachShader(shaderProgram, vertShader); 
         gl.attachShader(shaderProgram, fragShader);
         gl.linkProgram(shaderProgram);
         gl.useProgram(shaderProgram);

         /* Step 4: Associate the shader programs to buffer objects */

         gl.bindBuffer(gl.ARRAY_BUFFER, vertex_buffer);

         var coord = gl.getAttribLocation(shaderProgram, "coordinates");

         //point an attribute to the currently bound VBO
         gl.vertexAttribPointer(coord, 2, gl.FLOAT, false, 0, 0);

         gl.enableVertexAttribArray(coord);

				 return shaderProgram;
			}

function drawModel(gl) {
         // Clear the canvas
         gl.clearColor(0.5, 0.5, 0.5, 0.9);

         gl.enable(gl.DEPTH_TEST);
         gl.clear(gl.COLOR_BUFFER_BIT);
         gl.viewport(0,0,1280,720);

         gl.drawArrays(gl.TRIANGLES, 0, 3);

				 return gl;
		}

function MODEL(args) {
		var gl = window.gl;
		var positions = new Float32Array(args[0]);
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

		return ((args) => {
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
	}
