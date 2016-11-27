var root = document.getElementById('tree');
root.path = '/';
selected = localStorage.selected;

var ext = {
	'.asm': 'asm',
	'.c': 'clike',
	'.cpp': 'clike',
	'.css': 'css',
	'.cxx': 'clike',
	'.c++': 'clike',
	'.exe': 'plain',
	'.html': 'xml',
	'.htm': 'xml',
	'.js': 'javascript',
	'.json': 'javascript',
	'.lua': 'lua',
	'.s': 'gas',
	'.sas': 'sas',
	'.txt': 'text',
	'.xml': 'xml',
}

function hexInt(d) {
	return  ("0000000"+(Number(d).toString(16).toUpperCase())).slice(-8).toUpperCase()
}

function hex(data) {
	var res = "";
	for (var i = 0; i < data.length; i++) {
		if ((i % 16) == 0)
			res += hexInt(i) + '\t';
		res += hex_encode(data[i]);
		res += ' ';
		if ((i % 16) == 15) {
			var text = data.substr(i-15,16);
			text = text.replace(/[\n\r\t]/g, '\x00');
			res += ' ' + text + '\n';
		}
	}
	return res;
}

function select(el) {
	if (selected != null)
		selected.classList.remove('selected');
	selected = el;
	read("/" + el.path, function(data) {
	if (el.path.endsWith('.json')) {
		try {
			data = JSON.stringify(JSON.parse(data), null, 4)
		} catch (obj) {
			// nothing
		}
	}
	if (el.path.endsWith('.exe'))
		data = hex(data);
	
	// set editor mode
	for (var e in ext) {
		if (selected.path.endsWith(e)) {
			editor.setOption('mode', ext[e]);
			break;
		}
	}
	editor.setValue(data);
	editor.clearHistory();
	el.classList.add('selected');
	localStorage.selected = selected.id;
	});
}

function fold(el) {
	var folded = localStorage['@folded'];
	if (folded)
		folded = JSON.parse(folded);
	else
		folded = {};
	folded[el.path] = !folded[el.path];
	console.log(JSON.stringify(folded));
	localStorage['@folded'] = JSON.stringify(folded);
}

function dirElement(parent, path) {
	var el = document.createElement('div');
	el.className = 'branch dir';
	el.path = path;
	el.tabIndex = '-1';
	el.id = path;
	var stub = path.split('/')[path.split('/').length - 2];
	el.innerHTML = stub + '/';
	el.addEventListener('click', function() {
		fold(el);
		fill(parent);
	});
	el.addEventListener('keypress', function(e) {
		if (e.keyCode == 46) {
			rm(path);
			fill(parent);
		}
	});
	return el;
}

function fileElement(parent, path) {
	var el = document.createElement('div');
	el.className = 'branch file';
	el.path = path;
	el.tabIndex = '-1';
	el.id = path;
	var stub = path.split('/')[path.split('/').length - 1];
	el.innerHTML = stub;
	el.addEventListener('click', function() {
		select(el);
	});
	el.addEventListener('keypress', function(e) {
		if (e.keyCode == 46) {
			rm(path);
			fill(parent);
		}
	});
	return el;
}

function fill(root) {
	root.innerHTML = "";
	
	// skip?
	var folded = localStorage['@folded'];
	if (folded) {
		folded = JSON.parse(folded);
		if (folded[root.path])
			return;
	}
	
	var files = ls(root.path, function(files) {
	
	// create file
	{
		var el = document.createElement('div');
		el.className = 'branch touch';
		el.innerHTML = '+';
		el.tabIndex = files.length;
		root.appendChild(el);
		el.addEventListener('click', function() {
			create(root.path);
		});
	}
	for (var i = 0; i < files.length; i++) {
		if (files[i].endsWith('/')) {
			var el1 = dirElement(root, files[i]);
			var el2 = document.createElement('div');
			el2.path = files[i];
			el2.style = 'padding-left: 16px;'
			fill(el2);
			root.appendChild(el1);
			root.appendChild(el2);
		}
		else {
			var el = fileElement(root, files[i]);
			root.appendChild(el);
		}
	}
	});
}

function create(root) {
	var name = prompt('Name?');
	if (name == null)
		return;
	name = root + name;
	console.log(name);
	if (name != null) {
		if (name.endsWith('/'))
			mkdir(name);
		else
			write(name, '');
		fill(tree);
	}
}

// RESET
if (!selected || !localStorage[selected]) {
	console.log("RESET");
	write('/main.lua', "for k,v in pairs(_G) do\n\tprint(k,v)\r\nend");
	fill(root);
}

// initial
fill(root);
selected = document.getElementById(localStorage.selected);

select(selected || root.childNodes[1]);
