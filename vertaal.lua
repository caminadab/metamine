require 'util'
require 'ontleed'
require 'typeer'
require 'bouw.arch'
require 'bouw.controle'
require 'optimaliseer'
require 'oplos'

function vertaal(code, doel)
	local doel = doel or "lua"
	local maakvar = maakvars()

	local asb,syntaxfouten = ontleed(code)
	local asb2 = ontleed(file('bieb/'..doel..'.code'))
	local asb = cat(asb, asb2)
	asb.fn = X'EN'

	local types,typeerfouten = typeer(asb)
	local mach = arch_x64(asb, types)
	local uit,oplosfouten = oplos(mach, "app")
	--local uit = optimaliseer(uit)
	local fouten = cat(syntaxfouten, typeerfouten, oplosfouten)
	local app = controle(uit, maakvar)

	return app, fouten
end

if test then
	require 'doe'

	local function test(code, moet)
		local v = vertaal(code, 'ifunc')
		local imm = doe(v)
		assert(imm == moet, string.format('vertaal("%s") moet %s zijn maar was %s', code, moet, imm))
	end

	-- arith
	test('uit = 3', 3)
	test('uit = 2 + 1', 3)
	test('uit = 1 / 2 + 1 / 2', 1)
	test('a = 1 + 1\nb = a - a + a\nuit = a · b', 4)

	-- alsdan
	test('uit = als 2 > 1 dan 1 anders -1', 1)
	test('uit = als 2 < 1 dan 1 anders -1', -1)
	test('a = als 2 < 1 dan 1 anders -1\nuit = als a > 0 dan a - 1 anders a + 1', 0)

	-- functies
	test("f = a → a + 1\nuit = f(-1)", 0)

	local itoatoitoa = [[
uit = "looptijd: " || itoa(atoi(itoa(atoi(itoa(atoi(itoa(-3)))))))

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
  a = neg || ((n .. 0) map cijfer)
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
