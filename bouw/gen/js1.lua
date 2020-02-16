require 'exp'

local function val2js(val)
	if obj(val) == "," then
		return "["..table.concat(imap(val, val2js), ",").."]"
	elseif obj(val) == "[]" then
		return "["..table.concat(imap(val, val2js), ",").."]"
	elseif obj(val) == "{}" then
		return "new Set(["..table.concat(imap(val, val2js), ",").."])"
	elseif atoom(val) == '⊤' then
			return 'true'
	elseif atoom(val) == '⊥' then
			return 'false'
	elseif atoom(val) == 'π' then
			return 'Math.PI'
	elseif atoom(val) == 'τ' then
			return 'Math.PI*2'
	elseif atoom(val) == '∅' then
			return '[]'
	elseif tonumber(atoom(val)) then
		return atoom(val)
	else
		error(combineer(val) .. ' is geen jsval')
		--return false
	end
end

local fn2js = {
	['atoom'] = 'atoom$1',
	['%'] = '$1 / 100;',
	['+'] = '$1 + $2;',
	['-'] = '$1 = - $1',
	['¬'] = '$1 = ! $1',
	['mod'] = '$1 %= $2',

	['plus'] = '$1 += $2;',
	['deel'] = '$1 /= $2;',
	['rdeel'] = '$2 /= $1;',
	['maal'] = '$1 *= $2;',
	['push'] = '$1 = $2;',
	['wissel'] = '[$1,$2] = [$2,$1];',

	['fn.eerste'] = '$1 = $1[1];',
	['fn.tweede'] = '$1 = $1[2];',
	['fn.derde'] = '$1 = $1[3];',
	['fn.vierde'] = '$1 = $1[4];',

	['abs'] = '$1 = Math.abs($1);',

	['tekst'] = '$1 = ($1).toString();',


	['∧'] = '$1 = $1 && $2;',
	['∨'] = '$1 = $1 || $2;',

	['<'] = '$1 = $1 < $2;',
	['≤'] = '$1 = $1 <= $2;',
	['='] = '$1 = JSON.stringify($1) == JSON.stringify($2);',
	['≥'] = '$1 = $1 >= $2;',
	['>'] = '$1 = $1 > $2;',

	['kleinerdan'] = '$1 = $1 < $2;',
	['kleinergelijk'] = '$1 = $1 <= $2;',
	['gelijk'] = '$1 = $1 == $2;',
	['grotergelijk'] = '$1 = $1 >= $2;',
	['groterdan'] = '$1 = $1 > $2;',
	['dan'] = '$1 = $2 ? $1 : null;',
	['als'] = '$1 = $1 ? $2 : null;',

	['⇒'] = '$1 = $1 ? $2 : null;',
	['|'] = '$1 = $1 || $2;',

	-- gfx
	['label'] = [[ $1 = (xyz) => {
		return (c => {
			var x = xyz[0][0];
			var y = xyz[0][1];
			var t = xyz[1];
			c.font = "48px Arial";
			c.fillText(t, x * 7.2, 720 - (y * 7.2) - 1);
			return c;
		});]],
	['rechthoek'] = '(function(pos) {return (function(c){\n\t\tvar x = pos[0][0] + 17.778/2; var y = pos[0][1]; var w = pos[1][0] - x; var h = pos[1][1] - y;\n\t\tc.beginPath();\n\t\tc.rect(x * 7.2, 720 - ((y+h) * 7.2) - 1, w * 7.2, h * 7.2);\n\t\tc.fill();\n\t\treturn c;}); })($1);',
	['cirkel'] = '(function(xyz) {return (function(c){\n\t\tvar x = xyz[0][0] || xyz[0]; var y = xyz[0][1] || xyz[1]; var r = xyz[0][0] ? xyz[1] : 1/xyz[2];\n\t\tc.beginPath();\n\t\tc.arc(x * 7.2, 720 - (y * 7.2) - 1, Math.max(r,0) * 7.2, 0, Math.PI * 2);\n\t\tc.fill();\n\t\treturn c;}); })',
	['boog'] = '(function(xyz) {return (function(c){\n\t\tvar x = xyz[0][0]; var y = xyz[0][1]; var r = xyz[1]; var a1 = xyz[2]; var a2 = xyz[3];\n\t\tc.beginPath();\n\t\tc.arc(x * 7.2, 720 - (y * 7.2) - 1, r * 7.2, a1, a2);\n\t\tc.fill();\n\t\treturn c;}); })',
	['vierkant'] = '(function(xyr) {return (function(c){\n\t\tvar x = xyr[0][0];\n\t\tvar y = xyr[0][1];\n\t\tvar d = xyr[1] || 1.0;\n\t\tc.beginPath();\n\t\tc.rect(x * 7.2, 720 - ((y+d) * 7.2) - 1, d * 7.2, d * 7.2);\n\t\tc.fill();\n\t\treturn c;}); })',
}

function jsgen(im)

	local focus = 1
	local uit = {}

	local function emit(fmt, ...)
		local args = {...}
		uit[#uit+1] = fmt:gsub('$(%d)', function(i) return args[tonumber(i)] end)
	end
	
	local function insgen(ins)
		local b = varnaam(focus-1)
		local a = varnaam(focus)

		if fn2js[atoom(ins)] then
			emit(fn2js[atoom(ins)], a, b)
			if fn2js[atoom(ins)]:match('$2') then
				focus = focus - 1
			end

		elseif atoom(ins) == 'constant' then
			emit("$1 = x => $2;", a, b)
			focus = focus + 1

		-- functioneel
		elseif fn(ins) == 'wissel' then
			local num = assert(tonumber(atoom(arg(ins))))
			local a = varnaam(focus)
			local b = varnaam(focus + num)
			emit("[$1,$2] = [$2,$1];", a, b, b, a)

		elseif fn(ins) == 'push' then
			local js = val2js(arg(ins))
			emit("$1 = $2;", a, js)
			focus = focus + 1

		elseif fn(ins) == 'rep' then
			local x = varnaam(focus)
			for i=1,#arg(ins) do
				focus = focus + 1
				local a = varnaam(focus)
				emit("var $1 = $2;", a, js)
			end
			focus = focus + 1

		elseif tonumber(atoom(ins)) then
			local js = val2js(ins)
			emit("$1 = $2;", a, js)
			focus = focus + 1

		else
			error('ONBEKEND: ' ..lenc(ins))
			emit("// " .. combineer(ins))
		end

	end

	for i, ins in ipairs(im) do
		insgen(ins)
	end

	return table.concat(uit, '\n')
end
