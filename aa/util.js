

function hex_encode(data) {
	var res = "";
	for (var i = 0; i < data.length; i++) {
		var num = data.charCodeAt(i).toString(16);
		if (num.length == 1)
			num = '0' + num;
		res += num;
	}
	return res;
}

function hex_decode(data) {
	var res = "";
	for (var i = 0; i < data.length; i+= 2)
		res += String.fromCharCode(parseInt(data.substring(i,i+2), 16));
	return res;
}