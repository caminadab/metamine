require 'util'
require 'ontleed'
require 'typeer'
require 'bouw.arch'
require 'bouw.codegen'
require 'optimiseer'
require 'vertolk'
require 'oplos'


function scope(x)
	local maakvar = maakvars()
	for exp in boompairs(x) do
		if fn(exp) == '→' then
			for naam in pairs(var(exp.a[1])) do
				local nnaam = X('scope'..maakvar()..'.'..naam.v)
				x.a = substitueer(x.a, naam, nnaam)
				--exp.a[2] = substitueer(exp.a[2], naam, nnaam)
			end
		end
	end
	return x
end

local diop2js = {
	['+'] = '+=',
	['·'] = '*=',
	['/'] = '/=',
}

local diops = {
	['>'] = '>',
	['≥'] = '>=',
	['='] = '==',
	['≤'] = '<=',
	['<'] = '<',
}

local function genjs(sfc)
	local focus = 1
	local gen = {}
	gen[#gen+1] = 'function main(A) {'
	for i,ins in ipairs(sfc) do
		if diop2js[atoom(ins)] then
			local a = varnaam(focus-2)
			local b = varnaam(focus-1)
			local op = diop2js[atoom(ins)]
			gen[#gen+1] = string.format('%s %s %s;', a, op, b)
			focus = focus - 1
		elseif diops[atoom(ins)] then
			gen[#gen+1] = string.format('var %s = %s %s %s;', varnaam(focus), atoom(ins), varnaam(focus-1))
		elseif fn(ins) == 'put' then
			gen[#gen+1] = string.format('var %s = %s;', varnaam(focus), atoom(arg(ins)))
		elseif fn(ins) == 'push' then
			focus = focus + 1
			gen[#gen+1] = string.format('var %s = %s;', varnaam(focus), atoom(arg(ins)))
		elseif atoom(ins) == 'dup' then
			gen[#gen+1] = string.format('var %s = %s;', varnaam(focus+1), varnaam(focus))
			focus = focus + 1
		elseif atoom(ins) == 'trip' then
			gen[#gen+1] = string.format('var %s = %s;', varnaam(focus+1), varnaam(focus))
			gen[#gen+1] = string.format('var %s = %s;', varnaam(focus+2), varnaam(focus))
			focus = focus + 2
		else
			gen[#gen+1] = '// '..combineer(ins)
		end
	end
	gen[#gen+1] = 'return A;'
	gen[#gen+1] = '}'
	return table.concat(gen, '\n')
end

function vectoriseer(asb, types)
	for exp in boompairsdfs(asb) do

		-- L_i → (_i)(L, i)
		if fn(exp) == '_' then
			local fntype = types[moes(arg0(exp))]
			local islijst = atoom(arg0(fntype)) == 'nat'
			if islijst then
				exp.f = X'_l'
			else
				exp.f = X'_f'
			end
		end

		-- (F^i) → (^)(F, i)
		if fn(exp) == '^' then
			local basetype = types[moes(arg0(exp))]
			local isgetal = atoom(basetype) == 'getal' or atoom(basetype) == 'int'
			if isgetal then
				exp.f = X'^r'
			else
				exp.f = X'^f'
			end
		end

	end
	return asb
end

-- code → struct
function vertaal(code, naam)
	local naam = naam or '?'
	local maakvar = maakvars()

	local asb,syntaxfouten,map = ontleed(code, naam)
	--local scoped = scope(asb)
	if type(asb) ~= 'table' then
		return nil, { syntaxfout(nergens, "rommel"); }
	end

	-- vertaal
	local asb = vertolk(asb)

	-- types
	local type,typeerfouten,types = typeer(asb)
	if #typeerfouten > 0 then
		return nil, cat(syntaxfouten, typeerfouten)
	end

	-- vectoriseer
	local asb = vectoriseer(asb, types)

	local exp,oplosfouten = oplos(asb, "app")
	
	if #oplosfouten > 0 then
		return nil, cat(syntaxfouten, typeerfouten, oplosfouten)
	end

	local app = codegen(exp)

	return app, {}, gen2bron
end

if test then
	require 'doe'

	-- fouten
	local _,f = vertaal('uit = )')
	assert(#f > 0)

	local function test(code, moet)
		local v,f = vertaal(code)
		if not v and #f > 0 then
			print('tijdens testen van '..code..':')
			for i,fout in ipairs(f) do
				print(fout2ansi(fout))
			end
		end
			
		local imm = doe(v)
		assert(imm == moet, string.format('vertaal("%s") moet %s zijn maar was %s', code, moet, imm))
	end

	-- arith
	test('uit = 3', 3)
	test('uit = 2 + 1', 3)
	test('uit = 1 / 2 + 1 / 2', 1)
	test('a = 1 + 1\nb = a - a + a\nuit = a · b', 4)

	-- alsdan
	--test('uit = als 2 > 1 dan 1 anders -1', 1)
	--test('uit = als 2 < 1 dan 1 anders -1', -1)
	--test('a = als 2 < 1 dan 1 anders -1\nuit = als a > 0 dan a - 1 anders a + 1', 0)

	-- functies
	test("f = a → a + 1\nuit = f(-1)", 0)

	-- componeer
	test("f = x → x · 2\ng = y → y - 1\nh = f ∘ g ∘ f ∘ f ∘ g\nuit = h(3)", 19)

	-- als
	opt = {L=true}
	test("als 2 > 1 dan\n\tuit = 2\nanders\n\tuit = 3\neind", 2)

	-- functietjes
	test([[
f = (a, b) → a + b
g = (c, d) → c + d

uit = f(g(2, 3), f(g(1, 8), 2))
]], 16)

	-- ez
	test('uit = "hoi"', 'hoi')
	test('uit = "hoi" ‖ "ja"', 'hoija')
	test([[
uit = "fib(20) = " ‖ tekst(x) ‖ [10]
x = fib 20
fib = n → (fⁿ[0,1]) 0
f = [a,b] → [b,a+b]
]], 6765)

	test([[
f = succ ∘ succ ∘ g
g = x → x · 2
uit = f(1)
]], 6)

	local itoatoitoa = [[
uit = "looptijd: " ‖ itoa(atoi(itoa(atoi(itoa(atoi(itoa(-3)))))))

; tekst -> integer
atoi = b → i
	; negatief?
	negatief = (b₀ = '-')
	sign = als negatief dan -1 anders 1

	; cijfers van de tekst
tekens = als negatief dan (b vanaf 1) anders (b)
cijfers = tekens map (t → t - '0')

; waarde van elk cijfer gegeven de positie
waarde = (k → cijfers(j) · 10^k)
	j = #tekens - k - 1

; positie en resultaat
pos = 0 .. #tekens
i = sign · Σ (pos map waarde)

; integer -> tekst
itoa = x → a
n = 1 + entier(log10(max(abs x, 1)))
neg = als x < 0 dan "-" anders ""
a = neg ‖ ((n .. 0) map cijfer)
geschaald = (abs x)/10^m
cijfer = m → '0' + (entier geschaald) mod 10
]]
test(itoatoitoa, -3)

local plus260 = [[
; 10 x 26 blok van vergelijkingen
uit = a
a = b + b + b + b + b + b + b + b + b + b
b = c + c + c + c + c + c + c + c + c + c 
c = d + d + d + d + d + d + d + d + d + d 
d = e + e + e + e + e + e + e + e + e + e 
e = f + f + f + f + f + f + f + f + f + f 
f = g + g + g + g + g + g + g + g + g + g 
g = h + h + h + h + h + h + h + h + h + h
h = i + i + i + i + i + i + i + i + i + i 
i = j + j + j + j + j + j + j + j + j + j 
j = k + k + k + k + k + k + k + k + k + k 
k = l + l + l + l + l + l + l + l + l + l 
l = m + m + m + m + m + m + m + m + m + m 
m = n + n + n + n + n + n + n + n + n + n
n = o + o + o + o + o + o + o + o + o + o 
o = p + p + p + p + p + p + p + p + p + p
p = q + q + q + q + q + q + q + q + q + q
q = r + r + r + r + r + r + r + r + r + r
r = s + s + s + s + s + s + s + s + s + s
s = t + t + t + t + t + t + t + t + t + t
t = u + u + u + u + u + u + u + u + u + u
u = v + v + v + v + v + v + v + v + v + v
v = w + w + w + w + w + w + w + w + w + w
w = x + x + x + x + x + x + x + x + x + x
x = y + y + y + y + y + y + y + y + y + y
y = z + z + z + z + z + z + z + z + z + z
z = 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1
]]

test(plus260, '1e+26')
end
