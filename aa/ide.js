var meat = document.getElementById('meat');
var out = document.getElementById('out');

editor = CodeMirror.fromTextArea(meat, {
	lineNumbers: true,
	//gutters: ['breakpoints'],
	indentUnit: 4,
	mode: 'lua',
	lineWrapping: true,
	cursorScrollMargin: 10,
	tabSize: 4,
	indentWithTabs: true,
	theme: 'slang',
	styleActiveLine: true,
	extraKeys: {
		'F1': function() {run(); return false;},
		'Ctrl-S': function() {download(); return false;},
	}
});

//setInterval(run, 1000);

var names = document.getElementsByClassName('name');
for (var i = 0; i < names.length; i++) {
	names[i].addEventListener('click', (function(j) {
		return function (e) {
			file = names[j].innerHTML;
			load(file);
		};
	})(i));
}

function download() {
	var zip = new JSZip();
	addZip(zip, '/');
	var blob = zip.generate({type:"blob"});
	saveAs(blob, "project.zip");
}

function run() {
	read('/main.lua', function(code) {
	code = code || editor.getValue();
	try {
		L.execute(`
		debug.getregistry()._LOADED = {}
		js.global.document:getElementById('out').innerHTML = '';
		`)
		L.execute(code);
	} catch (e) {
		addLuaError(editor, e.lua_stack);
		out.innerHTML += e.lua_stack || e.toString();
		out.innerHTML += '\n';
	}
	});
}

// errors
var backgrounds = [];
var bookmarks = [];

function addError(editor,line,err) {
	// background
	var h = editor.addLineClass(line, 'background', 'lua-error');
	backgrounds.push(h);
	
	// message
	var e = document.createElement('span');
	e.className = 'lua-error-message';
	if (err.length > 20)
		err = err.substr(0,20)+'...';
	e.innerHTML = err;
	var bm = editor.setBookmark({line: line, pos: 0}, {
		widget: e,
		insertLeft: true,
	});
	bookmarks.push(bm);
}

function removeErrors(editor) {
	// clear existing errors
	for (var i = 0; i < backgrounds.length; i++)
		editor.removeLineClass(backgrounds[i], 'background', 'lua-error');
	for (var i = 0; i < bookmarks.length; i++)
		bookmarks[i].clear();
	
	// reset
	backgrounds = [];
	bookmarks = [];
}

function addLuaError(editor, message) {
	// [string 'a']:1: undefined symbol
	var split = message.split(':');
	var line = parseInt(split[1]) - 1;
	//if (!split[2])
	//	alert(message);
	var msg = split[2].substr(1);
	addError(editor,line,msg);
}

function check() {
	removeErrors(editor);
	try {
		L.load(editor.getValue());
	} catch (e) {
		addLuaError(editor, e.message);
	}
}

function save(path) {
	var data = editor.getValue();
	write(path, data);
}

editor.on('change', function() {
	if (selected.path.endsWith('.lua'))
	{check(); }
	if (!selected.path.endsWith('.exe'))
		save(selected.path);
});

get('/ide/ide.lua', function(src) {
	L.execute(src);
});
