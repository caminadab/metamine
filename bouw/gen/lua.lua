require 'func'

local unops = {
	['abs'] = 'math.abs($1)',
	['-'] = '- $1',
	['Σ'] = 'local sum = 0; for k, v in ipairs($1) do sum = sum + v end; $1 = sum;',
	['log10'] = 'math.log10($1)',
	['log'] = 'math.log',
	['fn.id'] = '$1',
	['fn.eerste'] = '(type($1)=="function") and $1(0) or $1[1]',
	['fn.tweede'] = '(type($1)=="function") and $1(1) or $1[2]',
	['fn.derde'] = '(type($1)=="function") and $1(2) or $1[3]',
	['fn.vierde'] = '(type($1)=="function") and $1(3) or $1[4]',
	['fn.plus'] = 'function(x) return x + $1 end', 
	['fn.deel'] = 'function(x) return x / $1 end', 
	['fn.maal'] = 'function(x) return x * $1 end', 
	['fn.constant'] = 'function(x) return $1 end', 
}

local noops = {
	['fn.id'] = 'function(x) return x end',
	['fn.constant'] = 'function() return $1 end',
	['fn.merge'] = 'function(x) return {$1(x),$2(x)} end',
	['fn.plus'] = 'function(x) return function(y) return x + y end end',
	['∘'] = 'function(x) return $1($2(x)) end',
	['log10'] = 'math.log',
	['_f'] = 'local r = nil ; for i=1,$2 do r = $1(r) end ; return r',
	['⊤'] = 'true',
	['⊥'] = 'false',
	['∅'] = '{}',
	['τ'] = 'math.pi * 2',
	['π'] = 'math.pi',
	['fn.eerste'] = '(type($1)=="function") and $1(1) or $1[1]',
	['fn.tweede'] = '(type($1)=="function") and $1(2) or $1[2]',
	['fn.derde'] = '(type($1)=="function") and $1(3) or $1[3]',
	['fn.vierde'] = '(type($1)=="function") and $1(4) or $1[4]',
}

local diops = {
	['+'] = '$1 + $2',
	['¬'] = '! $1',
	['-'] = '- $1',
	['·'] = '$1 * $2',
	['/'] = '$1 / $2',
	['mod'] = '$1 % $2',
	['willekeurig'] = 'Math.random()*($2-$1) + $1', -- randomRange[0, 10]
	['√'] = 'math.sqrt($1, 0.5)',
	['^'] = 'math.pow($1, $2)',
	['^f'] = 'function(res) { for (var i = 0; i < $2; i++) res = $1(res); return res; }',
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
	['⇒'] = '$1 ? $2 : $3', 

	['sin'] = 'Math.sin($1)',
	['cos'] = 'Math.cos($1)',
	['tan'] = 'Math.tan($1)',
	['sincos'] = '[Math.cos($1), Math.sin($1)]',
	['cossin'] = '[Math.sin($1), Math.cos($1)]',

	-- discreet
	['min'] = 'Math.min($1,$2)',
	['max'] = 'Math.max($1,$2)',
	['afrond.onder'] = 'Math.floor($1)',
	['afrond']       = 'Math.round($1)',
	['afrond.boven'] = 'Math.ceil($1)',
	['int'] = 'Math.floor($1)',
	['abs'] = 'Math.abs($1)',
	['sign'] = '($1 > 0 ? 1 : -1)',

	-- exp
	-- concatenate
	['‖'] = 'Array.isArray($1) ? $1.concat($2) : $1 + $2',
	['‖u'] = '$1 + $2',
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
	end

	L[#L+1] = 'local A = ...'

	for i,ins in ipairs(sfc) do
		ins2lua(ins)
	end

	L[#L+1] = 'return A'
	return table.concat(L, '\n')
end
