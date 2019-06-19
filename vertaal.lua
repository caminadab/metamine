require 'util'
require 'ontleed'
require 'typeer'
require 'bouw.arch'
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
	local uit,oplosfouten = oplos(mach, "uit")
	--local uit = optimaliseer(uit)
	local fouten = cat(syntaxfouten, typeerfouten, oplosfouten)
	local app = controle(uit, maakvar)

	return app, fouten
end

if test then
	require 'doe'

	local function test(code, moet)
	print()
	print()
	print(code)
	print()
		local v = vertaal(code)
		local imm = doe(v)
		assert(imm == moet, 'klopt niet: '..tostring(imm))
	end

	-- arith
	test('uit = 3', 3)
	test('uit = 2 + 1', 3)
	test('uit = 1 / 2 + 1 / 2', 1)
	test('a = 1 + 1\nb = a - a + a\nuit = a · b', 4)

	-- alsdan
	test('uit = als 2 > 1 dan 1 anders - 1', 1)
	test('uit = als 2 < 1 dan 1 anders - 1', -1)
	opt = {L=true}
	verbozeIntermediair=true
	verbozeWaarde=true
	test('a = als 2 < 1 dan 1 anders - 1\nuit = als a > 0 dan a - 1 anders a + 1', 0)

	-- functies
	--opt = {L=true}
	--verbozeWaarde = true
	verbozeIntermediair=true
	verbozeWaarde=true
	test("f = a → a + 1\nuit = f(-1)", 0)
end
