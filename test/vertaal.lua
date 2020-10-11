require 'parse'
require 'util'
require 'build.gen.lua'
require 'build.codegen'
require 'compile'
require 'doe'

-- fouten
local _,f = compile('app = )')
assert(#f > 0)

local function test(code, moet)
	local v,f = compile(code)
	if not v and #f > 0 then
		print('tijdens testen van '..code..':')
		for i,fout in ipairs(f) do
			print(fout2ansi(fout))
		end
	else
		print(color.cyan..code..color.white..' = '..color.green..lenc(moet)..color.white)
	end
		
	local imm = doe(v)
	if lenc(imm) ~= lenc(moet) then
		print(string.format('compile("%s") moet %s zijn maar was %s. imcode: %s', code, moet, imm, table.concat(map(v,deparse), " ")))
	end
end

-- arith
test('main = 3', 3)
test('main = 2 + 1', 3)
test('main = 1 / 2 + 1 / 2', 1)
test('a = 1 + 1\nb = a - a + a\nmain = a · b', 4)

-- sets
test('main = (1 ∈ {2,3})', false)
test('main = (2 ∈ {2,3})', true)

-- concat
test('main = #(a || a)\na = [1,2,3]', 6)

-- alsdan
test('als 2 > 1 dan\nmain = 1\nanders\nmain = -1\neind', 1)
test('als 1 > 2 dan\nmain = 1\nanders\nmain = -1\neind', -1)

-- functies
test("f = a → a + 1\nmain = f(-1)", 0)

-- componeer
test("f = x → x + 1\ng = f ∘ f\nmain = g(0)", 2)
test("f = x → x + 1\ng = f ∘ f ∘ f\nmain = g(0)", 3)
test("f = x → x · 2\ng = y → y - 1\nh = f ∘ g ∘ f ∘ f ∘ g\nmain = h(3)", 19)

-- als
test("als 2 > 1 dan\n\tmain = 2\nanders\n\tmain = 3\neind", 2)

-- functietjes
test([[
f = (a, b) → a + b
g = (c, d) → c + d

main = f(g(2, 3), f(g(1, 8), 2))
]], 16)

-- ez
test('main = "hoi"', 'hoi')
test('main = "hoi" ‖ "ja"', 'hoija')
test([[
main = fib 20
fib = n → ((f^n) (0,1)) 0
f = (a,b) → (b,a+b)
]], 6765)

--[=[
test([[
succ = y → y + 1
f = succ ∘ succ ∘ g
g = x → x · 2
main = f(1)
]], 6)

local itoatoitoa = [[
main = "looptijd: " ‖ itoa(atoi(itoa(atoi(itoa(atoi(itoa(-3)))))))

; text -> integer
atoi = b → i
; negatief?
negatief = (b₀ = '-')
sign = als negatief dan -1 anders 1

; cijfers van de text
tekens = als negatief dan (b vanaf 1) anders (b)
cijfers = tekens map (t → t - '0')

; waarde van elk cijfer gegeven de positie
waarde = (k → cijfers(j) · 10^k)
j = #tekens - k - 1

; positie en resultaat
pos = 0 .. #tekens
i = sign · Σ (pos map waarde)

; integer -> text
itoa = x → a
n = 1 + entier(log10(max(abs x, 1)))
neg = als x < 0 dan "-" anders ""
a = neg ‖ ((n .. 0) map cijfer)
geschaald = (abs x)/10^m
cijfer = m → '0' + (entier geschaald) mod 10
]]
test(itoatoitoa, -3)
]=]

local plus260 = [[
; 10 x 26 blok van vergelijkingen
main = a
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

test(plus260, 1e+26)
