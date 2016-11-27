var ckeywords = 'and break elseif false nil not or return true function end if then else do while repeat until for in local';
var keywords = {};

var akeywords = ckeywords.split(' ');
for (var i = 0; i < akeywords.length; i++)
	keywords[akeywords[i]] = true;

// editor
editor.on('keydown',function(cm,event) {
	if (event.keyCode == 8 && !editor.somethingSelected()) {
		var cursor = editor.getCursor();
		var from = {
			line: cursor.line,
			ch: cursor.ch - 1,
		}
		//var line = editor.getRange(from, cursor);
		var token = editor.getTokenAt(from);
		if (token && keywords[token.string]) {
			var start = { line: cursor.line, ch: token.start }
			var stop = { line: cursor.line, ch: token.stop }
			editor.replaceRange('', start, cursor);
		}
	}
	
	if (event.keyCode == 800) {
		var cursor = editor.getCursor();
		var from = {
			line: cursor.line - 3,
			ch: cursor.ch
		}
		var orig = editor.getRange(from, cursor);
		var fresh = orig.replace(/^|\s+$/g,'');
		
		if (orig != fresh && !editor.somethingSelected()) {
			editor.replaceRange(fresh, from, cursor);
			event.preventDefault();
		}
	}
});