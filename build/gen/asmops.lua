unops = {
	['#'] = '# $1',
	['%'] = '$1 / 100',
	['abs'] = 'math.abs($1)',
	['-'] = '- $1',
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

noops = {
	['map'] = '(function (tf) local t,f = tf[1],tf[2]; local r = {} ; for k,v in pairs(t) do r[k] = f(v); end ; return r; end)',
	['vouw'] = '(function(lf) local l,f,r = lf[1],lf[2],lf[1][1] ; for i=2,#l do r = f(r); end ; return r)',
	['mod'] = 'function(x) return x[1] % x[2] end',

	['text'] = 'text',

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

	-- dynamic
	['eerste'] = '(type($1)=="function") and $1(1) or $1[1]',
	['tweede'] = '(type($1)=="function") and $1(2) or $1[2]',
	['derde'] = '(type($1)=="function") and $1(3) or $1[3]',
	['vierde'] = '(type($1)=="function") and $1(4) or $1[4]',
}

diops = {
	['^f'] = '(function (f,n) for i=1,n do r = f(r) end ; return r; end)($1,$2)',
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

