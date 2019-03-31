require 'naarjavascript'

local html = [[
<canvas id="teke-ning" width="900" height="500">
</canvas>
<script>
// jslib
%s

// waarde
var doe = 0; //s;

var canvas = document.getElementById('teke-ning');
var ctx = canvas.getContext('2d');

function stap() {
	var tekening = %s; //doe();
	alert(JSON.stringify(tekening));
	for (var i = 0; i < tekening.length; i++) {
		var figuur = tekening[i];
		var vorm = figuur[0];
		var kleur = figuur[1];
		if (vorm[0] == 0) { // cirkel
			var x = vorm[1][0][0] * 500;
			var y = vorm[1][0][1] * 500;
			var r = vorm[1][1] * 500;
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
