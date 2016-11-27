// rm, ls, read, write,

function ziphelp(zip, dir) {
	var files = ls(dir);
	for (var i = 0; i < files.length; i++) {
		if (files[i][files[i].length-1] == '/')
			ziphelp(zip, files[i])
		else {
			var path = files[i].substring(1);
			zip.file(path, read(files[i]));
		}
	}
}

// zip directories
function zip(dir) {
	var zip = new JSZip();
	ziphelp(zip, dir);
	return zip;
}

function write(path, data) {
	// dir
	var dir = path.substring(0, path.lastIndexOf('/') + 1);
	var js = localStorage[dir];
	if (!js)
		js = '{}';
	var listing = JSON.parse(js);
	listing[path] = true;
	localStorage[dir] = JSON.stringify(listing);
	
	// file
	localStorage[path] = data;
}

function read(path,cb) {
	get(path, cb);
}

function mkdir(path) {
	var strip = path.substr(0,path.length - 1);
	var dir = path.substring(0, strip.lastIndexOf('/') + 1);
	var dict = {};
	if (localStorage[dir])
		dict = JSON.parse(localStorage[dir]);
	dict[path] = {};
	localStorage[path] = JSON.stringify(dict[path]);
	localStorage[dir] = JSON.stringify(dict);
}

function ls(path, cb) {
	get(path + ".dir.json", function(json) {
	
	var dir = path.substring(0, path.lastIndexOf('/') + 1);
	var dirs = [];
	var files = [];
	var dict = JSON.parse(json);
	
	for (var i in dict) {		
		if (dict[i].endsWith('/'))
			dirs.push(dict[i]);
		else
			files.push(dict[i]);
	}
	dirs.sort();
	files.sort();
	cb(dirs.concat(files));
	
	});
}

function rm(path) {
	var folder = path.substring(0, path.lastIndexOf('/') + 1);
	var files = JSON.parse(localStorage[folder]);
	delete files[path];
	
	localStorage[folder] = JSON.stringify(files);
	delete localStorage[path];
}

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

function bin_read(path) {
	var data = read(path);
	var uint8 = new Uint8Array(data.length);
	for (var i = 0; i < data.length; i++) {
		uint8[i] = data.charCodeAt(i);
	}
	return uint8;
}

function bin_write(path, data) {
	var res = "";
	for (var i = 0; i < data.length; i++) {
		res += String.fromCharCode(data[i]);
	}
	write(path, res);
}
