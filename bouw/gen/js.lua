require 'func'

local unops = {
	['#'] = '$1.length',
	['√'] = 'Math.sqrt($1)',
	['%'] = '$1 / 100;',
	['-'] = '- $1',
	['¬'] = '! $1',
	['!'] = [[(num => {
  if (num === 0 || num === 1)
    return 1;
  for (var i = num - 1; i >= 1; i--) {
    num *= i;
  }
  return num;})($1)
	]],
	['Σ'] = '(x => {var sum = 0; for (var i = 0; i < $1.length; i++) { sum = sum + $1[i]; }; return sum;})()',
	['|'] = '((alts) => { for (var i=0; i<alts.length; i++) {  var alt = alts[i]; if (alt != null) {return alt;} } })($1)',
}

local fnops = {
	['fn.nul'] = '$1(0)',
	['fn.een'] = '$1(1)',
	['fn.twee'] = '$1(2)',
	['fn.drie'] = '$1(3)',

	['l.eerste'] = '$1[0]',
	['l.tweede'] = '$1[1]',
	['l.derde'] = '$1[2]',
	['l.vierde'] = '$1[3]',
}

local noops = {
	['afrond.onder'] = 'Math.floor',
	['afrond']       = 'Math.round',
	['afrond.boven'] = 'Math.ceil',
	['willekeurig'] = 'x => Math.random()*(x[1]-x[0]) + x[0]',
	['int'] = 'Math.floor',
	['abs'] = 'Math.abs',
	['tekst'] = 'x => JSON.stringify(x) || (x || "niets").toString()',
	['vierkant'] = [[ args => {
  var x = args[0][0];
  var y = args[0][1];
  var r = args[1];
  return context => {
		context.fillStyle = 'white';
    context.fillRect(x,y,r,r);
    return context;
  }
  } ]],

	['label'] = [[ args => {
  var x = args[0][0];
  var y = args[0][1];
  var t = args[1];
  return context => {
		context.fillStyle = 'white';
    context.fillText(t,x,y);
    context.fillText(t,x,y);
    return context;
  }
	} ]],

	['rechthoek'] = [[ args => {
  var x = args[0][0];
  var y = args[0][1];
  var w = args[1][0] - x;
  var h = args[1][1] - y;
  return context => {
		context.fillStyle = 'white';
    context.fillRect(x,y,w,h);
    return context;
  }
	} ]],
	-- cirkel = fillStyle("#fff") ∘ beginPath ∘ arc(x -> x || (0, τ)) ∘ fillPath

	['cirkel'] = [[ args => {
		return (function(c){
			var x = args[0][0];
			var y = args[0][1];
			var r = args[1];
			c.fillStyle = 'white';
			c.beginPath();
			c.arc(x, y, r, 0, Math.PI * 2);
			c.fill();
			return c;
		});
	}]],

	['boog'] = [[ (function(xyz) {return (function(c){\n\t\tvar x = xyz[0][0]; var y = xyz[0][1]; var r = xyz[1]; var a1 = xyz[2]; var a2 = xyz[3];\n\t\tc.beginPath();\n\t\tc.arc(x * 7.2, 720 - (y * 7.2) - 1, r * 7.2, a1, a2);\n\t\tc.fill();\n\t\treturn c;}); }) ]],

	['canvas.clear'] = '(function(c) { c.clearRect(0,0,1900,1200); return c; })',

	['sign'] = '$1 > 0 and 1 or -1',
	['map'] = 'tf => tf[0].map(tf[1])',
	['vouw'] = '(function(lf) {var l=lf[0]; var f=lf[1]; var r=l[0] ; for (var i=1; i < l.length; i++) r = f([r, l[i]]); ; return r;})',
	['mod'] = 'x => x[0] % x[1]',

	['int'] = 'Math.floor',
	['sin'] = 'Math.sin',
	['cos'] = 'Math.cos',

	['|'] = '$1 or $2',
	['fn.id'] = 'x => x',
	['fn.constant'] = 'function() return $1 end',
	['fn.merge'] = '{$1(x),$2(x)}',
	['fn.plus'] = 'function(x) return function(y) return x + y end end',
	['-'] = 'function(x) return -x end',
	['log10'] = 'math.log10',
	['⊤'] = 'true',
	['⊥'] = 'false',
	['∅'] = '{}',
	['τ'] = 'Math.PI * 2',
	['π'] = 'Math.PI',
	['_f'] = '$1($2)',
	['l.eerste'] = '$1[0]',
	['l.tweede'] = '$1[1]',
	['l.derde'] = '$1[2]',
	['l.vierde'] = '$1[3]',
	['fn.nul'] = '$1(0)',
	['fn.een'] = '$1(1)',
	['fn.twee'] = '$1(2)',
	['fn.drie'] = '$1(3)',

	-- dynamisch
	['eerste'] = '(typeof($1)=="function") ? $1(0) : $1[0]',
	['tweede'] = '(typeof($1)=="function") ? $1(1) : $1[1]',
	['derde'] = '(typeof($1)=="function") ? $1(2) : $1[2]',
	['vierde'] = '(typeof($1)=="function") ? $1(3) : $1[3]',
}

local binops = {
	-- set
	[':'] = '$2.has($1)',
	['∩'] = 'new Set([...$1].filter(x => $2.has(x)))',
	['∪'] = 'new Set([...$1, ...$2])',
	['-s'] = 'new Set([...$1].filter(x => !$2.has(x)))',
	['+v']  = '(x => {var r = []; for (var i = 0; i < $1.length; i++) r.push($1[i] + $2[i]); return r;})()',
	['+v1'] = '$1.map(x => x + $2)',
	['·v']  = '(x => {var r = []; for (var i = 0; i < $1.length; i++) r.push($1[i] * $2[i]); return r;})()',
	['·v1'] = '$1.map(x => x * $2)',
	['+f'] = '$1.map(x => x + $2)',
	['·f1'] = '$1.map(x => x + $2)',
	['/v1'] = '$1.map(x => x / $2)',
	['_f'] = '$1($2)',
	['_l'] = '$1[$2]',
	['_'] = 'typeof($1) == "function" ? $1($2) : $1[$2]',
	['^r'] = '$1 ^ $2',
	['∘'] = '((a,b) => (x => b(a(x))))($1,$2)',
	['+'] = '$1 + $2',
	['·'] = '$1 * $2',
	['/'] = '$1 / $2',
	['^'] = '$1 ^ $2',
	['×'] = '(ab => { var r = []; for (var i = 0; i < $1.length; i++) { for (var j = 0; j < $2.length; j++) { r.push([$1[i],$2[j]]); }} ; return r;})()',
	['..'] = '$1 == $2 ? [] : ($1 <= $2 ? Array.from(new Array(Math.max(0,Math.floor($2 - $1))), (x,i) => $1 + i) : Array.from(new Array(Math.max(0,Math.floor($1 - $2))), (x,i) => $1 - 1 - i))',
	['mod'] = '$1 % $2',

	['|'] = '$1 or $2',

	['√'] = 'Math.sqrt($1, 0.5)',
	['^'] = 'Math.pow($1, $2)',
	['^f'] = [[(function (f,n) {
		return function(x) {
			var r = x;
			for (var i = 0; i < n; i++) {
				r = f(r);
			}
			return r;
		}
	})($1,$2)]],
	['derdemachtswortel'] = 'Math.pow($1,1/3)',

	-- cmp
	['>'] = '$1 > $2',
	['≥'] = '$1 >= $2',
	['='] = '$1 === $2',
	['≠'] = '$1 !== $2',
	['≤'] = '$1 <= $2',
	['<'] = '$1 < $2',

	-- deduct
	['∧'] = '$1 && $2', 
	['∨'] = '$1 || $2', 
	['⇒'] = '$1 && $2', 

	['sincos'] = '{Math.cos($1), Math.sin($1)}',
	['cossin'] = '{Math.sin($1), Math.cos($1)}',

	-- discreet
	['min'] = 'Math.min($1,$2)',
	['max'] = 'Math.max($1,$2)',

	-- exp
	-- concatenate
	['‖'] = [[typeof($1) == "string" ? $1 + $2 : $1.concat($2)]],
	['‖u'] = '$1 .. $2',
	['‖i'] = '(for i,v in ipairs(b) do a[#+1] = v)($1,$2)',
	['mapuu'] = '(function() { var totaal = ""; for (int i = 0; i < $1.length; i++) { totaal += $2($1[i]); }; return totaal; })() ', -- TODO werkt dit?
	['catu'] = '$1.join($2)',
}

function jsgen(sfc)

	local maakvar = maakindices()
	local L = {}
	if opt and opt.L then
		setmetatable(L, {__newindex = function (t,k,v) rawset(L, k, v); print(v); end })
	end
	local tabs = ''
	local focus = 1

	local function emit(fmt, ...)
		local args = {...}
		uit[#uit+1] = fmt:gsub('$(%d)', function(i) return args[tonumber(i)] end)
	end

	function ins2lua(ins)
		if fn(ins) == 'push' or fn(ins) == 'put' then
			if fn(ins) == 'push' then
				focus = focus + 1
			end
			local naam = atoom(arg(ins))
			assert(naam, unlisp(ins))
			naam = noops[naam] or naam
			L[#L+1] = string.format('%svar %s = %s;', tabs, varnaam(focus), naam), focus

		elseif atoom(ins) == 'fn.id' then
			-- niets

		elseif tonumber(atoom(ins)) then
			L[#L+1] = tabs..'var '..varnaam(focus) .. " = " .. atoom(ins) .. ';'
			focus = focus + 1

		elseif fn(ins) == 'rep' then
			local res = {}
			local num = tonumber(atoom(arg(ins)))
			assert(num, unlisp(ins))
			for i = 1, num-1 do
				L[#L+1] = tabs..string.format('var %s = %s;', varnaam(focus+i), varnaam(focus))
				focus = focus + 1
			end

		elseif fn(ins) == '∘' then
			local funcs = arg(ins)
			L[#L+1] = tabs..string.format('function %s(x) {')
			for i, func in ipairs(funcs) do
				local naam = varnaam(focus - i + 1)
				L[#L+1] = tabs..'  x = '..naam
			end
			L[#L+1] = tabs..string.format('function %s(x) {')

		elseif fn(ins) == 'wissel' then
			local naama = varnaam(focus)
			local num = atoom(arg(ins))
			local naamb = varnaam(focus + num)
			L[#L+1] = tabs..string.format('var %s,%s = %s,%s;', naama, naamb, naamb, naama)

		elseif unops[atoom(ins)] then
			local naam = varnaam(focus-1)
			local di = unops[atoom(ins)]:gsub('$1', naam)
			L[#L+1] = tabs..string.format('var %s = %s;', naam, di)

		elseif binops[atoom(ins)] then
			local naama = varnaam(focus-2)
			local naamb = varnaam(focus-1)
			local di = binops[atoom(ins)]:gsub('$1', naama):gsub('$2', naamb)
			L[#L+1] = tabs..string.format('var %s = %s;', naama, di)
			focus = focus - 1

		elseif atoom(ins) == 'eind' then
			local naama = varnaam(focus-1)
			local naamb = varnaam(focus-2)
			L[#L+1] = tabs..'return '..naama..';'
			tabs = tabs:sub(3)
			L[#L+1] = tabs.."}"
			focus = focus - 1

		elseif atoom(ins) == 'einddan' then
			local naam = varnaam(focus-1)
			local tempnaam = 'tmp'
			L[#L+1] = tabs .. tempnaam .. " = " .. naam .. ';'
			tabs = tabs:sub(3)
			L[#L+1] = tabs.."} else tmp = null;"
			L[#L+1] = tabs..'var ' .. naam .. " = " .. tempnaam .. ';'
			focus = focus

		-- biebfuncties?
		elseif noops[atoom(ins)] then
			L[#L+1] = tabs..'var '..varnaam(focus) .. " = " .. noops[atoom(ins)] .. ';'
			focus = focus + 1

		elseif fn(ins) == 'set' then
			local set = {}
			local num = tonumber(atoom(arg(ins)))
			local naam = varnaam(focus - num)
			for i=1,num do
				set[i] = varnaam(i + focus - num - 1)
			end
			L[#L+1] = tabs..string.format("var %s = new Set([%s]);", naam, table.concat(set, ","))
			focus = focus - num + 1


		elseif fn(ins) == 'tupel' or fn(ins) == 'lijst' then
			local tupel = {}
			local num = tonumber(atoom(arg(ins)))
			local naam = varnaam(focus - num)
			for i=1,num do
				tupel[i] = varnaam(i + focus - num - 1)
			end
			L[#L+1] = tabs..string.format("var %s = [%s];", naam, table.concat(tupel, ","))
			focus = focus - num + 1

		elseif fn(ins) == 'string' then
			local text = {}
			local num = tonumber(atoom(arg(ins)))
			local naam = varnaam(focus - num)
			for i=1,num do
				text[i] = varnaam(i + focus - num - 1)
			end
			L[#L+1] = tabs..string.format("var %s = String.fromCharCode(%s);", naam, table.concat(text,  ","))
			focus = focus - num + 1

		elseif fn(ins) == 'arg' then
			local var = varnaam(tonumber(atoom(arg(ins))))
			local naam = varnaam(focus)
			L[#L+1] = tabs..'var '..naam..' = arg'..var..';'
			focus = focus + 1

		elseif fn(ins) == 'fn' then
			local naam = varnaam(focus)
			local var = varnaam(tonumber(atoom(arg(ins))))
			L[#L+1] = tabs..string.format("var %s = (%s) => {", naam, "arg"..var)
			focus = focus + 1
			tabs = tabs..'  '

		elseif atoom(ins) == 'dan' then
			focus = focus-1
			local naam = varnaam(focus)
			L[#L+1] = tabs..string.format("if (%s) {", naam)
			tabs = tabs..'  '

		else
			error('onbekende instructie: '..unlisp(ins))

		end
		--L[#L+1] = 'print("'..L[#L]..'")'
		--L[#L+1] = 'print('..varnaam(focus)..')'
	end

	for i = 1, #sfc do
		local ins = sfc[i]
		ins2lua(ins)
	end

	L[#L+1] = 'return A;'

	return table.concat(L, '\n')
end
