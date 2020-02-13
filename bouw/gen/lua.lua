require 'func'

local unops = {
	['abs'] = 'math.abs($1)',
	['-'] = '- $1',
	['Σ'] = 'local sum = 0; for k, v in ipairs($1) do sum = sum + v end; $1 = sum;',
	['log10'] = 'math.log10($1)',
	['log'] = 'math.log',
	['fn.id'] = '$1',
	['fn.eerste'] = '$1(0)',
	['fn.tweede'] = '$1(1)',
	['fn.derde'] = '$1(2)',
	['fn.vierde'] = '$1(3)',
	['l.eerste'] = '$1[1]',
	['l.tweede'] = '$1[2]',
	['l.derde']  = '$1[3]',
	['l.vierde'] = '$1[4]',
	['fn.plus'] = 'function(x) return x + $1 end', 
	['fn.deel'] = 'function(x) return x / $1 end', 
	['fn.maal'] = 'function(x) return x * $1 end', 
	['fn.constant'] = 'function(x) return $1 end', 
}

local noops = {
	['fn.id'] = 'function(x) return x end',
	['fn.constant'] = 'function() return $1 end',
	['fn.merge'] = '{$1(x),$2(x)}',
	['fn.plus'] = 'function(x) return function(y) return x + y end end',
	['∘'] = 'function(x) return $1($2(x)) end',
	['log10'] = 'math.log',
	['+'] = 'function(x) return x[1] + x[2] end',
	--['+'] = 'function(x) return $1 + $2 end',
	['⊤'] = 'true',
	['⊥'] = 'false',
	['∅'] = '{}',
	['τ'] = 'math.pi * 2',
	['π'] = 'math.pi',
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

local diops = {
	['^f'] = '(function (f,n) for i=1,n do r = f(r) end ; return r; end)($1,$2)',
	['_f'] = '$1($2)',
	['_i'] = '$1[$2+1]',
	['fn.merge'] = '{$1(x), $2(x)}',
	['^r'] = '$1 ^ $2',
	['∘'] = 'function(x) return $2($1(x)) end',
	['+'] = '$1 + $2',
	['¬'] = '! $1',
	['-'] = '- $1',
	['·'] = '$1 * $2',
	['/'] = '$1 / $2',
	['mod'] = '$1 % $2',
	['willekeurig'] = 'math.random()*($2-$1) + $1', -- randomRange[0, 10]
	['√'] = 'math.sqrt($1, 0.5)',
	['^'] = 'math.pow($1, $2)',
	['derdemachtswortel'] = 'math.pow($1,1/3)',

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
	['⇒'] = '$1 ? $2 : $3', 

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

function luagen(sfc)

	local focus = 1
	local L = {}

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
			L[#L+1] = string.format('local %s = %s', varnaam(focus), naam), focus

		elseif atoom(ins) == 'fn.id' then
			-- niets

		elseif fn(ins) == 'rep' then
			local res = {}
			local num = tonumber(atoom(arg(ins)))
			assert(num, unlisp(ins))
			for i = 1, num-1 do
				L[#L+1] = string.format('local %s = %s', varnaam(focus+i), varnaam(focus))
				focus = focus + 1
			end

		elseif fn(ins) == 'wissel' then
			local naama = varnaam(focus)
			local num = atoom(arg(ins))
			local naamb = varnaam(focus + num)
			L[#L+1] = string.format('local %s,%s = %s,%s', naama, naamb, naamb, naama)

		elseif unops[atoom(ins)] then
			local naam = varnaam(focus)
			local di = unops[atoom(ins)]:gsub('$1', naam)
			L[#L+1] = string.format('local %s = %s', naam, di)

		elseif diops[atoom(ins)] then
			local naama = varnaam(focus-1)
			local naamb = varnaam(focus)
			local di = diops[atoom(ins)]:gsub('$1', naama):gsub('$2', naamb)
			L[#L+1] = string.format('local %s = %s', naama, di)
			focus = focus - 1

		else
			L[#L+1] = '-- ' .. unlisp(ins)
		end
		--L[#L+1] = 'print("'..L[#L]..'")'
		--L[#L+1] = 'print('..varnaam(focus)..')'
	end

	L[#L+1] = 'local A = ...'

	for i,ins in ipairs(sfc) do
		ins2lua(ins)
	end

	L[#L+1] = 'return A'
	return table.concat(L, '\n')
end
