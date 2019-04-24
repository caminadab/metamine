require 'naarjavascript'

local html = [[
<canvas id="teke-ning" width="900" height="500">
</canvas>
<script>
// jslib
%s

// waarde
var canvas = document.getElementById('teke-ning');
var ctx = canvas.getContext('2d');

function stap() {
	
	ctx.clearRect(0, 0, canvas.width, canvas.height);
	var tekening = %s; //doe();
	for (var i = 0; i < tekening.length; i++) {
		var figuur = tekening[i];

		 // cirkel
		if (figuur[0] == 0) {
			var x = figuur[1][0] * 500;
			var y = figuur[1][1] * 500;
			var r = figuur[2] * 500;
			if (figuur[3]) {
				var R = figuur[3][0];
				var G = figuur[3][1];
				var B = figuur[3][2];
				ctx.fillStyle = 'rgb('+R*255+','+G*255+','+B*255+')'
			}
			ctx.beginPath();
			ctx.arc(x, y, r, 0, 2 * Math.PI);
			ctx.fill(); 
		}

		// vierkant
		if (figuur[0] == 1) {
			var x1 = figuur[1][0] * 500;
			var y1 = figuur[1][1] * 500;
			var x2 = figuur[2][0] * 500;
			var y2 = figuur[2][1] * 500;
			if (figuur[3]) {
				var R = figuur[3][0];
				var G = figuur[3][1];
				var B = figuur[3][2];
				ctx.fillStyle = 'rgb('+R*255+','+G*255+','+B*255+')'
			}
			ctx.rect(x1, y1, x2, y2);
			ctx.fill(); 
		}

		// tekst
		if (figuur[0] == 2) {
			var x1 = figuur[1][0] * 500;
			var y1 = figuur[1][1] * 500 + 48;
			var a = figuur[2];
			var t = arr2str(a);
			if (figuur[3]) {
				var R = figuur[3][0];
				var G = figuur[3][1];
				var B = figuur[3][2];
				ctx.fillStyle = 'rgb('+R*255+','+G*255+','+B*255+')'
			}
			ctx.font = "48px Arial";
			ctx.fillText(t, x1, y1);
		}
	}
}

var istap;

function probeerstap() {
	try {
		stap();
	}
	catch (e) {
		clearInterval(istap);
		alert("Executiefout! " + e);
		alert(e.message || e.getMessage());
	}
}

istap = setInterval(probeerstap, 16);

</script>
]]
function naarweb(exp)
	local js = naarjavascript(exp)
	local web = string.format(html, javascriptbieb, js)
	return web
end
