require 'ontleed'
require 'bouw.gen.lua'
require 'bouw.codegen'
require 'vertaal'
require 'doe'

-- fouten
local _,f = vertaal('app = )')
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
	assert(imm == moet, string.format('vertaal("%s") moet %s zijn maar was %s. imcode: %s', code, moet, imm, table.concat(map(v,combineer), " ")))
end

-- arith
test('app = 3', 3)
test('app = 2 + 1', 3)
test('app = 1 / 2 + 1 / 2', 1)
test('a = 1 + 1\nb = a - a + a\napp = a · b', 4)

-- alsdan
--test('app = als 2 > 1 dan 1 anders -1', 1)
--test('app = als 2 < 1 dan 1 anders -1', -1)
--test('a = als 2 < 1 dan 1 anders -1\napp = als a > 0 dan a - 1 anders a + 1', 0)

-- functies
test("f = a → a + 1\napp = f(-1)", 0)

-- componeer
test("f = x → x + 1\ng = f ∘ f\napp = g(0)", 2)
test("f = x → x + 1\ng = f ∘ f ∘ f\napp = g(0)", 3)
test("f = x → x · 2\ng = y → y - 1\nh = f ∘ g ∘ f ∘ f ∘ g\napp = h(3)", 19)

-- als
test("als 2 > 1 dan\n\tapp = 2\nanders\n\tapp = 3\neind", 2)

-- functietjes
test([[
f = (a, b) → a + b
g = (c, d) → c + d

app = f(g(2, 3), f(g(1, 8), 2))
]], 16)

-- ez
test('app = "hoi"', 'hoi')
test('app = "hoi" ‖ "ja"', 'hoija')
test([[
app = "fib(20) = " ‖ tekst(x) ‖ [10]
x = fib 20
fib = n → (fⁿ[0,1]) 0
f = [a,b] → [b,a+b]
]], 6765)

test([[
f = succ ∘ succ ∘ g
g = x → x · 2
app = f(1)
]], 6)

local itoatoitoa = [[
app = "looptijd: " ‖ itoa(atoi(itoa(atoi(itoa(atoi(itoa(-3)))))))

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
app = a
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
