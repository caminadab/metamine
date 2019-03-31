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
		if (figuur[0] == 0) { // cirkel
			var x = figuur[1][0] * 500;
			var y = figuur[1][1] * 500;
			var r = figuur[2] * 500;
			ctx.beginPath();
			ctx.arc(x, y, r, 0, 2 * Math.PI);
			ctx.fill(); 
		}
	}
}

setInterval(stap, 16);
</script>
]]
function naarweb(exp)
	local js = naarjavascript(exp)
	local web = string.format(html, javascriptbieb, js)
	return web
end
