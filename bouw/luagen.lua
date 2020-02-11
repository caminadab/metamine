local binop  = set("+","·","/","^"," ","∨","∧","×","..","→","∘","_","‖","⇒",">","≥","=","≠","≈","≤","<",":=","+=","|:=", "∪","∩",":","∈")
local unop   = set("-","#","¬","Σ","|","%","√","!", "%","!",".","'")

local imm = {
	['niets'] = 'undefined',
	['dt'] = 'dt',
	['[]'] = '[$ARGS]',
	['[]u'] = '$TARGS',
	['{}'] = 'new Set([$ARGS])',

	-- arit
	['misschien'] = 'Math.random() < 0.5',
	['map'] = '$1.map($2)',
	['vouw'] = '$1.length == 0 ? (x => x) : $1.length == 1 ? $1[0] : $1.slice(1).reduce((x,y) => $2([x,y]),$1[0])',
	['atoom'] = 'atoom$1',
	['%'] = '$1 / 100',

	['¬'] = '! $1',
	['_'] = '$1($2)',

	['+'] = '$1 + $2',
	['-'] = '- $1',
	['·'] = '$1 * $2',
	['/'] = '$1 / $2',

	['mod'] = '$1 % $2',

	['willekeurig'] = 'Math.random()*($2-$1) + $1', -- randomRange[0, 10]
	['√'] = 'Math.pow($1, 0.5)',
	['^'] = 'Math.pow($1, $2)',
	['^f'] = 'function(res) { for (var i = 0; i < $2; i++) res = $1(res); return res; }',
	['wortel'] = 'Math.sqrt($1)',
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

	['sin'] = 'math.sin($1)',
	['cos'] = 'math.cos($1)',
	['tan'] = 'math.tan($1)',
	['sincos'] = '{math.cos($1), math.sin($1)}',
	['cossin'] = '{math.sin($1), math.cos($1)}',

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
	['log10'] = 'math.log10($1)',
	-- concatenate
	['‖'] = 'Array.isArray($1) ? $1.concat($2) : $1 + $2',
	['‖u'] = '$1 + $2',
	['mapuu'] = '(function() { var totaal = ""; for (int i = 0; i < $1.length; i++) { totaal += $2($1[i]); }; return totaal; })() ', -- TODO werkt dit?
	['catu'] = '$1.join($2)',

	-- lijst
	['#'] = '$1.length',
	['Σ'] = '(function(t) local sum = 0; for i, v in ipairs(t) do sum = sum + v end; return sum)($1)',
	['..'] = '$1 == $2 ? [] : ($1 <= $2 ? Array.from(new Array(Math.max(0,Math.floor($2 - $1))), (x,i) => $1 + i) : Array.from(new Array(Math.max(0,Math.floor($1 - $2))), (x,i) => $1 - 1 - i))',
	['_u'] = '$1[$2]',
	['vanaf'] = '$1.slice($2, $1.length)',

	['×'] = '[].concat.apply([], $1.map(x => $2.map(y => Array.isArray(x) ? Array.from(x).concat([y]) : [x, y])))', -- cartesisch product

	['∘'] = 'function(x) return $2($1(x)) end',
}

local immf = {}
for k,v in pairs(imm) do
	if v:match('$2') then
		immf[k] = string.format('function(x) return %s end', v:gsub('$1', 'x[1]'):gsub('$2', 'x[2]'))
	else
		immf[k] = string.format('function(x) return %s end', v:gsub('$1', 'x'))
	end
end

local function ins2lua(ins, stack)
	local focus = stack[#stack]

	-- doet 1 op de stack erbij
	if fn(ins) == 'push' then
		local a = varnaam(focus)
		stack[#stack] = focus + 1
		local exp = atoom(arg(ins))
		local exp = immf[exp] or exp
		return string.format('local %s = %s', a, exp)
	
	-- dupliceer 1 waarde
	elseif atoom(ins) == 'dup' then
		local a = varnaam(focus + 1)
		local b = varnaam(focus + 0)
		stack[#stack] = focus + 1
		return string.format('local %s = %s', a, b)
	
	elseif atoom(ins) == 'rouleer' then
		stack[#stack] = focus - 0

	-- haalt 1 van de stack af
	elseif binop[atoom(ins)] then
		local a = varnaam(focus - 2)
		local b = varnaam(focus - 1)

		stack[#stack] = focus - 1
		local exp = imm[atoom(ins)]:gsub('$1',a):gsub('$2',b)
		return string.format('local %s = %s', a, exp)
	
	-- houdt de stack gelijk
	elseif unop[atoom(ins)] then
		local a = varnaam(focus - 1)
		local exp = imm[atoom(ins)]:gsub('$1',a)
		return string.format('local %s = %s', a, exp)
	
	else
		return '-- '..combineer(ins)
	end
end


function luagen(im)
	local lua = {}
	local stack = {1}
	
	lua[#lua+1] = 'local A = ...'

	for i, ins in ipairs(im) do
		lua[#lua+1] = ins2lua(ins, stack)
	end

	lua[#lua+1] = 'return A'

	return table.concat(lua, '\n')
end
