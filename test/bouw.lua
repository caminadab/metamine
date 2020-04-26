require 'bouw.assembleer'
require 'bouw.link'
require 'bouw.gen.asm'
require 'bouw.gen.lua'
require 'bouw.gen.js'
require 'vertaal'
require 'doe'

function doelua(lua)
	return load(lua)()
end

function doeasm(asm)
	file('.test.s', asm)
	local elf = link(assembleer(asm, 'test'))
	file('.test.elf', elf)
	os.execute('chmod +x .test.elf')
	os.execute('./.test.elf ; echo $? > .test.out')
	local uit = file('.test.out')
	os.execute('rm .test.out')
	os.execute('rm .test.elf')
	local uit = uit:sub(1,#uit-1)
	return uit
end

function doejs(js)
	local src = "process.exit((function() {\n" .. js .. "\n})())"
	file('.test.js', src)
	os.execute('node .test.js ; echo $? > .test.out')
	local uit = file('.test.out')
	os.execute('rm .test.out')
	local uit = uit:sub(1,#uit-1)
	return uit
end

function test(code, moetzijn)
	-- niet optimaliseren aub
	opt = {['0'] = false}
	local im,fouten = vertaal(code)
	assert(im, "onvertaalbaar: "..code)

	local js  = jsgen(im)
	local asm = asmgen(im)


	local imval = tostring(doe(im))
	local asmval = tostring(doeasm(asm))
	local jsval = tostring(doejs(js))

	print(code)
	print('Im', 'Js', 'Asm')
	print(imval, jsval, asmval)
	print()

	if imval ~= asmval or imval ~= jsval then

		print('# Im')
		for i,ins in ipairs(im) do
			print(unlisp(ins))
		end
		print()

		if imval ~= jsval then
			print('# Javascript')
			print(js)
			print()
		end
		if imval ~= asmval then
			print('# Assembly')
			print(asm)
			print()
		end

		--assert(false)
	end

end

-- arit
test("main = 2", 2)
test("main = 1 + 2", 3)
test("main = 1 + 2 · 3", 7)
test("main = 6 - 2", 4)

-- functioneel
test("f = x → x + 1\nmain = f(1)", 2)
test("f = x → x + 1\nmain = (f ∘ f)(1)", 3)
test("f = x → x + 1\nmain = (f ^ 3)(1)", 4)

-- logica
test("main = (ja ⇒ 2)", 2)


test([[
f = x → x + 10
g = y → y + 100
h = (f ∘ g)³
main = h(3)]],
333)
test("main = (x → x + 1)(2)", 3)
test("main = [1,2,3] vouw (+)", 6)
test([[
f = x,y → y,x 
a = f(2, 3)
main = a₀
]], 3)

test([[
sgn = x → y

als x < 0 dan
	y = -1
anders
	y = 1
end

main = sgn 3
]], 1)

test('main = -3' --[[
main = itoa(atoi(itoa(atoi(itoa(atoi(itoa(-3)))))))

; tekst -> integer
atoi = b → i
	; negatief?
	als b₀ = '-' dan
		sign = -1
		tekens = b vanaf 1
	anders
		sign = 1
		tekens = b
	eind

	; cijfers van de tekst
  cijfers = tekens map (t → t - '0')
	cijfers = tekens zip1 ('0') map (-)

	; waarde van elk cijfer gegeven de positie
  waarde = (k → cijfers(j) · 10^k)
    j = #tekens - k - 1

	; positie en resultaat
	pos = 0 .. #tekens
  i = sign · Σ (pos map waarde)

; integer -> tekst
itoa = x → a
  n = 1 + ⌊log10(max(abs x, 1))⌋
	als x < 0 dan
		neg = "-"
	anders
		neg = ""
	eind
  a = neg ‖ ((n .. 0) map cijfer)
  geschaald = (abs x)/10^m
  cijfer = m → '0' + ⌊geschaald mod 10⌋
]], -3)

print('alles ok')
