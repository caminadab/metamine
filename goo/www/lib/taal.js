// CodeMirror, copyright (c) by Marijn Haverbeke and others
// Distributed under an MIT license: http://codemirror.net/LICENSE

// LUA mode. Ported to CodeMirror 2 from Franciszek Wawrzak's
// CodeMirror 1 mode.
// highlights keywords, strings, comments (no leveling supported! ("[==[")), tokens, basic indenting

(function(mod) {
  if (typeof exports == "object" && typeof module == "object") // CommonJS
    mod(require("../../lib/codemirror"));
  else if (typeof define == "function" && define.amd) // AMD
    define(["../../lib/codemirror"], mod);
  else // Plain browser env
    mod(CodeMirror);
})(function(CodeMirror) {
"use strict";

CodeMirror.defineMode("taal", function(config, parserConfig) {
  var indentUnit = config.indentUnit;

  function prefixRE(words) {
    return new RegExp("^(?:" + words.join("|") + ")", "i");
  }
  function wordRE(words) {
    return new RegExp("^(?:" + words.join("|") + ")$", "i");
  }
  var specials = wordRE(parserConfig.specials || []);

  // long list of standard functions from lua manual
  var builtins = wordRE([
    "niets", "teken", "uit", "ja", "nee", "fout", "∅",
		"tekst", "int", "getal", "cijfer", "letter", "witruimte",

		// engels
		"none", "canvas", "out", "yes", "no", "error",
		"text", "int", "number", "digit", "letter", "whitespace",

		// tekening
		"rood", "groen", "blauw", "oranje", "paars", "zwart", "wit", "grijs", "beige", "bruin", "geel", "cyaan",
		"cirkel", "rechthoek", "vierkant", "lijn", "label", "boog", "polygoon", "map", "zip", "vouw", "sin", "cos", "tan", "abs",
		"atan",

		// drawing
		"red", "green", "blue", "orange", "purple", "black", "white", "grey", "beige", "brown", "yellow", "cyan",
		"circle", "rectangle", "square", "line", "label", "arc", "polygon", "map", "zip", "fold", "sin", "cos", "tan", "abs",
  ]);
	var keywords = wordRE([
		"als","dan","andersals", "anders","eind",
		"if","then","elseif","else","end","herhaal","repeat","fout","error",
		"en", "of", "and", "or", "xof", "noch",
	]);

  var indentTokens = wordRE(["dan", "then"]);//"function", "if","repeat","do", "\\(", "{", "\\["]);
	var dedentTokens = wordRE(["anders", "andersals", "eind", "else", "elseif", "end"]);//"end", "until", "\\)", "}"]);
	var dedentPartial = prefixRE(["anders", "andersals", "else", "elseif"]);//"end", "until", "\\)", "}", "\\]", "else", "elseif"]);

	// getallen
	var subp = new Set( ('∞ τ ₀ ₁ ₂ ₃ ₄ ² ³').split(' '));
	var operatoren = new Set( (': = > < ≈ ≠ ≥ ≤ ≈ × → ↦ ⊂ ∪ ∩ ∧ ∨ Σ ∘ ⇒ Δ · ⌊ ⌋ ⌈ ⌉ ∏ ∐ ‖').split(' ') );
	var symbolen = new Set( ('ℝ ℕ ℤ ℚ 𝔹 ℍ ∅ ø ∞ τ ★ ☆').split(' ') );

  function normal(stream, state) {
    var ch = stream.next();
	
	// comment
	if (ch == ';' && stream.eat('-')) {
		var last = ' ';
		while (true) {
			var cur = stream.next();
			if (cur == null)
				break;
			if (last == '-' && cur == ';')
				break;
			last = cur;
		}
		return 'comment';
	}
	if (ch == ';') {
	  stream.skipToEnd();
	  return "comment";
	}
	
	// string
    if (ch == "\"")
      return (state.cur = string(ch))(stream, state);
  
	// number
    if (/[A-F\d\:]/.test(ch)) {
      stream.eatWhile(/[A-F\d\:\.]/);
	  if (stream.eat('h'))
		return 'number';
    }
	if (ch == '⁻' && stream.eat('¹')) return 'number';
	if (subp.has(ch)) return 'number';

	if (/[\d]/.test(ch)) {
		stream.eatWhile(/[\d\.]/);
		stream.eat(/e\-?/);
		stream.eat(/[\d\.]/);
		stream.eatWhile('h');
		return 'number';
	}
    if (/[\w]/.test(ch)) {
      stream.eatWhile(/[\da-zA-Z]/);
      return "variable";
    }
	
	// compare
	if (ch == '-' && stream.eat('>'))
		return 'operator';
	if (ch == '<' && stream.eat('='))
		return 'operator';
	if (ch == '>' && stream.eat('='))
		return 'operator';
	if (ch == '=' && stream.eat('='))
		return 'operator';
	if (ch == '≥' || ch == '≤' || ch == '≠')
		return 'operator';
	if (ch == '¬')
		return 'operator';
	if (ch == '→' || ch == '⇒' || ch == '↦')
		return 'operator';
	if (ch == '·' || ch == '/')
		return 'operator';
	if (ch == '^')
		return 'operator';
	if (ch == '|' && stream.eat('|'))
		return 'operator';
	if (ch == '|')
		return 'operator';
	if (operatoren.has(ch))
		return 'operator';
	if (symbolen.has(ch))
		return 'builtin';
	
	// group
	if (ch == '(' || ch == ')' || ch == '.' || ch == ',')
		return 'operator';
	
	// math
	if (/\=|\*|\+|\-|\/|\[|\]|\(|\)|\{|\}/.test(ch))
		return 'operator';
	
    return null;
  }

  function string(quote) {
    return function(stream, state) {
      var escaped = false, ch;
      while ((ch = stream.next()) != null) {
        if (ch == quote && !escaped) break;
        escaped = !escaped && ch == "\\";
      }
      if (!escaped) state.cur = normal;
      return "string";
    };
  }

  return {
    startState: function(basecol) {
      return {basecol: basecol || 0, indentDepth: 0, cur: normal};
    },

    token: function(stream, state) {
      if (stream.eatSpace()) return null;
      var style = state.cur(stream, state);
      var word = stream.current();
      if (style == "variable") {
        if (keywords.test(word)) style = "keyword";
        else if (builtins.test(word)) style = "builtin";
        else if (specials.test(word)) style = "variable-2";
      }
      if ((style != "comment") && (style != "string")){
        if (indentTokens.test(word)) ++state.indentDepth;
        else if (dedentTokens.test(word)) --state.indentDepth;
      }
      return style;
    },

    indent: function(state, textAfter) {
      var closing = dedentPartial.test(textAfter);
      return state.basecol + indentUnit * (state.indentDepth - (closing ? 1 : 0));
    },
  };
});

CodeMirror.defineMIME("text/x-taal", "taal");

});
