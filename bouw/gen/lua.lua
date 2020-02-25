require 'func'

local unops = {
	['#'] = '# $1',
	['%'] = '$1 / 100',
	['abs'] = 'math.abs($1)',
	['-'] = '- $1',
	['¬'] = 'not $1',
	['Σ'] = 'local sum = 0; for k, v in ipairs($1) do sum = sum + v end; $1 = sum;',
	['log10'] = 'math.log10($1)',
	['log'] = 'math.log',
	['fn.id'] = '$1',
	['|'] = '(function(alts) for i,alt in ipairs(alts) do if alt then return alt end end end)($1)',

	['fn.nul'] = '$1(0)',
	['fn.een'] = '$1(1)',
	['fn.twee'] = '$1(2)',
	['fn.drie'] = '$1(3)',

	['l.eerste'] = '$1[1]',
	['l.tweede'] = '$1[2]',
	['l.derde'] = '$1[3]',
	['l.vierde'] = '$1[4]',

	['fn.plus'] = 'function(x) return x + $1 end', 
	['fn.deel'] = 'function(x) return x / $1 end', 
	['fn.maal'] = 'function(x) return x * $1 end', 
	['fn.constant'] = 'function(x) return $1 end', 
}

local noops = {
	['map'] = '(function (tf) local t,f = tf[1],tf[2]; local r = {} ; for k,v in pairs(t) do r[k] = f(v); end ; return r; end)',
	['vouw'] = '(function(lf) local l,f,r = lf[1],lf[2],lf[1][1] ; for i=2,#l do r = f{r,l[i]}; end ; return r; end)',
	['mod'] = 'function(x) return x[1] % x[2] end',

	['vanaf'] = [[
	function(a,van)
		local t = {f='[]'}
		for i=van+1,#a do
			t[#t+1] = a[i]
		end
		return t
	end;
	]],

	['zip1'] = [[function(a)
		local a,b = a[1],a[2]
		local v = {}
		for i=#a,1,-1 do
			v[i] = {a[i], b}
		end
		return v
	end]];

	['tekst'] = 'tostring',

	['|'] = '$1 or $2',
	['fn.id'] = 'function(x) return x end',
	['fn.constant'] = 'function() return $1 end',
	['fn.merge'] = '{$1(x),$2(x)}',
	['fn.plus'] = 'function(x) return function(y) return x + y end end',
	['-'] = 'function(x) return -x end',
	['log10'] = 'math.log',
	['+'] = 'function(x) return x[1] + x[2] end',
	['⊤'] = 'true',
	['⊥'] = 'false',
	['∅'] = '{}',
	['τ'] = 'math.pi * 2',
	['π'] = 'math.pi',
	['_f'] = '$1($2)',
	['l.eerste'] = '$1[1]',
	['l.tweede'] = '$1[2]',
	['l.derde'] = '$1[3]',
	['l.vierde'] = '$1[4]',
	['fn.nul'] = '$1(0)',
	['fn.een'] = '$1(1)',
	['fn.twee'] = '$1(2)',
	['fn.drie'] = '$1(3)',

	-- dynamisch
	['eerste'] = '(type($1)=="function") and $1(1) or $1[1]',
	['tweede'] = '(type($1)=="function") and $1(2) or $1[2]',
	['derde'] = '(type($1)=="function") and $1(3) or $1[3]',
	['vierde'] = '(type($1)=="function") and $1(4) or $1[4]',
}

local binops = {
	['^f'] = '(function (f,n) for i=1,n do r = f(r) end ; return r; end)($1,$2)',
	['..'] = [[(function(a, b)
		local r = {}
		if a > b then
			for i=a-1,b,-1 do
				r[#r+1] = i
			end
		elseif a == b then
			return {}
		else
			for i=a,b-1 do
				r[#r+1] = i
			end
		end
		return r
	end)($1,$2)]],

	['_f'] = '$1($2)',
	['_i'] = '$1[$2+1]',
	['_'] = 'type($1) == "function" and $1($2) or $1[$2+1]',
	['fn.merge'] = '{$1(x), $2(x)}',
	['^r'] = '$1 ^ $2',
	['∘'] = 'function(x) return $2($1(x)) end',
	['+'] = '$1 + $2',
	['-'] = '- $1',
	['·'] = '$1 * $2',
	['/'] = '$1 / $2',
	['^'] = '$1 ^ $2',

	['|'] = '$1 or $2',
	['∘'] = 'function(x) return $2($1(x)) end',

	['willekeurig'] = 'Math.random()*($2-$1) + $1', -- randomRange[0, 10]
	['fn.merge'] = '$1, $2',--function(x) return {$1(x),$2(x)} end',
	['√'] = 'math.sqrt($1, 0.5)',
	['^'] = 'math.pow($1, $2)',
	['^f'] = [[(function (f,n)
		return function(x)
			local r = x
			for i=1,n do
				r = f(r)
			end
			return r
		end
	end)($1,$2)]],
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

local triops = {
	--['_f2'] = '$1($2,$3)',
}

function luagen(sfc)

	local maakvar = maakindices()
	local L = {}
	local tabs = ''
	local focus = 1

	local function emit(fmt, ...)
		local args = {...}
		uit[#uit+1] = fmt:gsub('$(%d)', function(i) return args[tonumber(i)] end)
	end

	function ins2lua(ins)
		if fn(ins) == 'push' or fn(ins) == 'put' then
			local naam = atoom(arg(ins))
			assert(naam, unlisp(ins))
			naam = noops[naam] or naam
			L[#L+1] = string.format('%slocal %s = %s', tabs, varnaam(focus), naam), focus
			if fn(ins) == 'push' then
				focus = focus + 1
			end

		elseif atoom(ins) == 'fn.id' then
			-- niets

		elseif tonumber(atoom(ins)) then
			L[#L+1] = tabs..'local '..varnaam(focus) .. " = " .. atoom(ins)
			focus = focus + 1

		elseif fn(ins) == 'rep' then
			local res = {}
			local num = tonumber(atoom(arg(ins)))
			assert(num, unlisp(ins))
			for i = 1, num-1 do
				L[#L+1] = tabs..string.format('local %s = %s', varnaam(focus+i), varnaam(focus))
				focus = focus + 1
			end

		elseif fn(ins) == '∘' then
			local funcs = arg(ins)
			L[#L+1] = tabs..string.format('function %s(x)')
			for i, func in ipairs(funcs) do
				local naam = varnaam(focus - i + 1)
				L[#L+1] = tabs..'  x = '..naam
			end
			L[#L+1] = tabs..string.format('function %s(x)')

		elseif fn(ins) == 'wissel' then
			local naama = varnaam(focus)
			local num = atoom(arg(ins))
			local naamb = varnaam(focus + num)
			L[#L+1] = tabs..string.format('local %s,%s = %s,%s', naama, naamb, naamb, naama)

		elseif unops[atoom(ins)] then
			local naam = varnaam(focus-1)
			local di = unops[atoom(ins)]:gsub('$1', naam)
			L[#L+1] = tabs..string.format('local %s = %s', naam, di)

		elseif binops[atoom(ins)] then
			local naama = varnaam(focus-2)
			local naamb = varnaam(focus-1)
			local di = binops[atoom(ins)]:gsub('$1', naama):gsub('$2', naamb)
			L[#L+1] = tabs..string.format('local %s = %s', naama, di)
			focus = focus - 1

		elseif triops[atoom(ins)] then
			local naama = varnaam(focus-3)
			local naamb = varnaam(focus-2)
			local naamc = varnaam(focus-1)
			local di = triops[atoom(ins)]:gsub('$1', naama):gsub('$2', naamb):gsub('$3', naamc)
			L[#L+1] = tabs..string.format('local %s,%s = %s', naama, naamb, di)
			focus = focus - 2

		elseif atoom(ins) == 'eind' then
			local naama = varnaam(focus-1)
			local naamb = varnaam(focus-2)
			L[#L+1] = tabs..'return '..naama
			tabs = tabs:sub(3)
			L[#L+1] = tabs.."end"
			focus = focus - 1

		elseif atoom(ins) == 'einddan' then
			local naam = varnaam(focus-1)
			local tempnaam = 'tmp'
			L[#L+1] = tabs .. tempnaam .. " = " .. naam
			tabs = tabs:sub(3)
			L[#L+1] = tabs.."end"
			L[#L+1] = tabs..'local ' .. naam .. " = " .. tempnaam
			focus = focus

		-- biebfuncties?
		elseif noops[atoom(ins)] then
			L[#L+1] = tabs..'local '..varnaam(focus) .. " = " .. noops[atoom(ins)]
			focus = focus + 1

		elseif fn(ins) == 'set' then
			local set = {}
			local num = tonumber(atoom(arg(ins)))
			local naam = varnaam(focus - num)
			for i=1,num do
				set[i] = '[' ..varnaam(i + focus - num - 1) .. ']=true'
			end
			L[#L+1] = tabs..string.format("local %s = {%s}", naam, table.concat(set, ","))
			focus = focus - num + 1


		elseif fn(ins) == 'tupel' or fn(ins) == 'lijst' then
			local tupel = {}
			local num = tonumber(atoom(arg(ins)))
			local naam = varnaam(focus - num)
			for i=1,num do
				tupel[i] = varnaam(i + focus - num - 1)
			end
			L[#L+1] = tabs..string.format("local %s = {%s}", naam, table.concat(tupel, ","))
			focus = focus - num + 1

		elseif fn(ins) == 'string' then
			local text = {}
			local num = tonumber(atoom(arg(ins)))
			local naam = varnaam(focus - num)
			for i=1,num do
				text[i] = varnaam(i + focus - num - 1)
			end
			L[#L+1] = tabs..string.format("local %s = string.char(%s)", naam, table.concat(text,  ","))
			focus = focus - num + 1

		elseif fn(ins) == 'arg' then
			local var = varnaam(tonumber(atoom(arg(ins))))
			local naam = varnaam(focus)
			L[#L+1] = tabs..'local '..naam..' = arg'..var
			focus = focus + 1

		elseif fn(ins) == 'fn' then
			local naam = varnaam(focus)
			local var = varnaam(tonumber(atoom(arg(ins))))
			L[#L+1] = tabs..string.format("function %s(%s) ", naam, "arg"..var)
			focus = focus + 1
			tabs = tabs..'  '

		elseif atoom(ins) == 'dan' then
			focus = focus-1
			local naam = varnaam(focus)
			L[#L+1] = tabs..string.format("if %s then", naam)
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

	L[#L+1] = 'return A'

	return table.concat(L, '\n')
end
