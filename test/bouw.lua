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
	opt = {['0'] = true}
	local im = vertaal(code)
	assert(im, "onvertaalbaar: "..code)

	local lua = luagen(im)
	local js  = jsgen(im)
	local asm = asmgen(im)


	local imval = tostring(doe(im))
	local luaval = tostring(doelua(lua))
	local asmval = tostring(doeasm(asm))
	local jsval = tostring(doejs(js))

	print(code)
	print('Im', 'Lua', 'Js', 'Asm')
	print(imval, luaval, jsval, asmval)
	print()

	if imval ~= luaval or imval ~= asmval or imval ~= jsval then

		print('# Im')
		for i,ins in ipairs(im) do
			print(unlisp(ins))
		end
		print()

		if imval ~= luaval then
			print('# Lua')
			print(lua)
			print()
		end
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
	end

end

test("main = 2", 2)
test("main = 1 + 2", 3)
test("main = 1 + 2 · 3", 7)
test("main = 6 - 2", 4)
test("main = (ja ⇒ 2)", 2)
test([[
f = x → x + 10
g = y → y + 100
h = (f ∘ g)³
main = h(3)]],
333)
test("main = (x → x + 1)(2)", 3)

print('alles ok')
