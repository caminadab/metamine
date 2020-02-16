require 'func'

local unops = {
	['#'] = '$1 = $1.length;',
	['%'] = '$1 / 100;',
	['abs'] = 'Math.abs($1);',
	['-'] = '- $1',
	['Σ'] = 'var sum = 0; for k, v in ipairs($1) do sum = sum + v end; $1 = sum;',
	['log10'] = 'Math.log($1, 10)',
	['log'] = 'Math.log',
	['fn.id'] = '$1',
	['|'] = '(function(alts) { for (var i=0; i<alts.length; i++) { if (alt) return alt; }})($1)',

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
	['map'] = '(function(tf) {var t,f = tf[0],tf[1]; local r = {} ; for k,v in pairs(t) do r[k] = f(v); end ; return r;})',
	['vouw'] = '(function(lf) {var l,f,r = lf[0],lf[1],lf[0][0] ; for (var i=2; i < l.length; i++) r = f(r); ; return r;})',
	['mod'] = 'x => x[0] % x[1]',

	['tekst'] = 'tekst',

	['|'] = '$1 or $2',
	['fn.id'] = 'function(x) return x end',
	['fn.constant'] = 'function() return $1 end',
	['fn.merge'] = '{$1(x),$2(x)}',
	['fn.plus'] = 'function(x) return function(y) return x + y end end',
	['-'] = 'function(x) return -x end',
	['log10'] = 'math.log',
	['+'] = 'x => x[0] + x[1]',
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
	['eerste'] = '(type($1)=="function") and $1(0) or $1[0]',
	['tweede'] = '(type($1)=="function") and $1(1) or $1[1]',
	['derde'] = '(type($1)=="function") and $1(2) or $1[2]',
	['vierde'] = '(type($1)=="function") and $1(3) or $1[3]',
}

local diops = {
	['^f'] = '(function (f,n) for i=1,n do r = f(r) end ; return r; end)($1,$2)',
	['map'] = '$1.map($2)',
	['vouw'] = '$1.reduce($2)',
	['_f'] = '$1($2)',
	['_i'] = '$1[$2+1]',
	['_'] = 'type($1) == "function" and $1($2) or $1[$2+1]',
	['fn.merge'] = '{$1(x), $2(x)}',
	['^r'] = '$1 ^ $2',
	['∘'] = 'function(x) return $2($1(x)) end',
	['+'] = '$1 + $2',
	['·'] = '$1 * $2',
	['/'] = '$1 / $2',
	['^'] = '$1 ^ $2',
	['mod'] = '$1 % $2',

	['|'] = '$1 or $2',
	['∘'] = 'function(x) return $2($1(x)) end',

	['willekeurig'] = 'Math.random()*($2-$1) + $1', -- randomRange[0, 10]
	['fn.merge'] = '$1, $2',--function(x) return {$1(x),$2(x)} end',
	['√'] = 'Math.sqrt($1, 0.5)',
	['^'] = 'Math.pow($1, $2)',
	['^f'] = [[(function (f,n) {
		return function(x) {
			var r = x;
			for (var i = 0; i < n; i++) {
				r = f(r);
			}
			return r;
		})($1,$2)]],
	['derdemachtswortel'] = 'Math.pow($1,1/3)',
	['_f'] = '$1($2)',
	['_l'] = '$1[$2+1]',

	-- cmp
	['>'] = '$1 > $2',
	['≥'] = '$1 >= $2',
	['='] = '$1 === $2',
	['≠'] = '$1 !== $2',
	['≤'] = '$1 <= $2',
	['<'] = '$1 < $2',

	-- deduct
	['¬'] = 'not $1',
	['∧'] = '$1 and $2', 
	['∨'] = '$1 or $2', 
	['⇒'] = '$1 and $2', 

	['sin'] = 'math.sin($1)',
	['cos'] = 'math.cos($1)',
	['tan'] = 'math.tan($1)',
	['sincos'] = '{math.cos($1), math.sin($1)}',
	['cossin'] = '{math.sin($1), math.cos($1)}',

	-- discreet
	['min'] = 'math.min($1,$2)',
	['max'] = 'math.max($1,$2)',
	['afrond.onder'] = 'math.floor($1)',
	['afrond']       = 'math.round($1)',
	['afrond.boven'] = 'math.ceil($1)',
	['int'] = 'math.floor($1)',
	['abs'] = 'math.abs($1)',
	['sign'] = '$1 > 0 and 1 or -1',

	-- exp
	-- concatenate
	['‖'] = 'type($1) == "string" and $1 .. $2 or (for i,v in ipairs(b) do a[#+1] = v)($1,$2)',
	['‖u'] = '$1 .. $2',
	['‖i'] = '(for i,v in ipairs(b) do a[#+1] = v)($1,$2)',
	['mapuu'] = '(function() { var totaal = ""; for (int i = 0; i < $1.length; i++) { totaal += $2($1[i]); }; return totaal; })() ', -- TODO werkt dit?
	['catu'] = '$1.join($2)',
}

function jsgen(sfc)

	local focus = 1
	local maakvar = maakindices()
	local L = {}
	local tabs = ''

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
			L[#L+1] = tabs..'var '..varnaam(focus) .. " = " .. atoom(ins)..';'
			focus = focus + 1

		elseif fn(ins) == 'rep' then
			local res = {}
			local num = tonumber(atoom(arg(ins)))
			assert(num, unlisp(ins))
			for i = 1, num-1 do
				L[#L+1] = tabs..string.format('var %s = %s', varnaam(focus+i), varnaam(focus))
				focus = focus + 1
			end

		elseif fn(ins) == '∘' then
			local funcs = arg(ins)
			L[#L+1] = tabs..string.format('function %s(x) {')
			for i, func in ipairs(funcs) do
				local naam = varnaam(focus - i + 1)
				L[#L+1] = tabs..'  x = '..naam
			end
			L[#L+1] = tabs..'  return x;'
			L[#L+1] = tabs..'}'

		elseif fn(ins) == 'wissel' then
			local naama = varnaam(focus)
			local num = atoom(arg(ins))
			local naamb = varnaam(focus + num)
			L[#L+1] = tabs..string.format('var %s,%s = %s,%s;', naama, naamb, naamb, naama)

		elseif unops[atoom(ins)] then
			local naam = varnaam(focus-1)
			local di = unops[atoom(ins)]:gsub('$1', naam)
			L[#L+1] = tabs..string.format('var %s = %s;', naam, di)

		elseif fn(ins) == 'fn.plus' then
			local naam = varnaam(focus)
			local c = atoom(arg(ins))
			L[#L+1] = tabs..string.format('var %s = %s + %s;', naam, naam, c)

		elseif diops[atoom(ins)] then
			local naama = varnaam(focus-2)
			local naamb = varnaam(focus-1)
			local di = diops[atoom(ins)]:gsub('$1', naama):gsub('$2', naamb)
			L[#L+1] = tabs..string.format('var %s = %s;', naama, di)
			focus = focus - 1

		elseif atoom(ins) == 'eind' then
			local naama = varnaam(focus-1)
			local naamb = varnaam(focus-2)
			L[#L+1] = tabs.."return "..naama
			tabs = tabs:sub(3)
			L[#L+1] = tabs.."}"
			focus = focus - 1

		elseif atoom(ins) == 'einddan' then
			local naam = varnaam(focus-1)
			local tempnaam = 'tmp'
			L[#L+1] = tabs .. tempnaam .. " = " .. naam
			tabs = tabs:sub(3)
			L[#L+1] = tabs.."}"
			L[#L+1] = tabs..'var ' .. naam .. " = " .. tempnaam
			focus = focus - 1

		-- biebfuncties?
		elseif noops[atoom(ins)] then
			L[#L+1] = tabs..'var '..varnaam(focus) .. " = " .. noops[atoom(ins)]..';'
			focus = focus + 1

		elseif fn(ins) == 'set' then
			error'TODO'

		elseif fn(ins) == 'tupel' or fn(ins) == 'lijst' then
			local tupel = {}
			local num = tonumber(atoom(arg(ins)))
			local naam = varnaam(focus - num)
			for i=1,num do
				tupel[i] = varnaam(i + focus - num - 1)
			end
			L[#L+1] = tabs..string.format("var %s = [%s]", naam, table.concat(tupel, ","))
			focus = focus - num + 1

		elseif fn(ins) == 'arg' then
			local var = varnaam(tonumber(atoom(arg(ins))))
			local naam = varnaam(focus)
			L[#L+1] = tabs..'var '..naam..' = arg'..var..';'
			focus = focus + 1

		elseif fn(ins) == 'fn' then
			local naam = varnaam(focus)
			local var = varnaam(tonumber(atoom(arg(ins))))
			L[#L+1] = tabs..string.format("function %s(%s) {", naam, "arg"..var)
			focus = focus + 1
			tabs = tabs..'  '

		elseif atoom(ins) == 'dan' then
			local naam = varnaam(focus-1)
			L[#L+1] = tabs..string.format("if (%s) {", naam)
			tabs = tabs..'  '

		else
			error('onbekende instructie: '..unlisp(ins))
		end
		--L[#L+1] = 'print("'..L[#L]..'")'
		--L[#L+1] = 'print('..varnaam(focus)..')'
	end

	L[#L+1] = 'var A = ...'

	for i,ins in ipairs(sfc) do
		ins2lua(ins)
	end

	L[#L+1] = 'return A'
	return table.concat(L, '\n')
end
