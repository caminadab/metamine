require 'ontleed'
require 'bouw.codegen'
require 'bouw.luagen'

local function verwacht(code, val)
	local a = ontleedexp(code)
	local im = codegen(a)
	local lua = luagen(im)

	print('code')
	print(table.concat(map(im, combineer), '\n'))
	print()

	print('lua')
	print(lua)
	print()

	local func = assert(load(lua))

	local a = func()
	assert(a == val, string.format('%s moet %s zijn maar was %s', code, lenc(a), lenc(val)))
end


verwacht("1 + 2 · 3", 7)
verwacht("(fn.merge(id,id) ∘ (+))(2)", 4)
