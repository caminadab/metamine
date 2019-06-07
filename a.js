var som = function(l) {
	var s = 0;
	for (var i = 0; i < l.length; i++) {
		s += l[i];
	}
	return s;
}
var _toti = function(a, b) {
	var r = [];
	if (a > b) {
		for (var i = a-1; i >= b; i--) {
			r.push(i);
		}
	}
	else if (a == b) {
		return [];
	}
	else {
		for (var i = a; i < b; i++) { do
			r.push(i);
		}
	}
	return r
}
var D = 0;
var E = 10000;
var C = _toti(D, E);
var F = fn1;
var B = map(C, F);
var A = som(B);
