require 'bouw.gen.lua'
require 'ontleed'

function imparse(imcode)
	local im = X'[]'
	for line in imcode:gmatch('([^\n]+)') do
		local a, b = line:match('(%S+)%s+(%S+)')
		if a and b then
			im[#im+1] = X(a, b)
		else
			local a = line:match('(%S+)')
			im[#im+1] = X(a)
		end
	end
	return im
end


function verwacht(im, val)
	local lua = luagen(im)

	local func, err = load(lua)
	assert(not err, tostring(err) .. '\n' .. lua)

	local ok,res = pcall(func)
	assert(ok, tostring(res) .. '\n' .. lua)

	if res ~= val then
		print(string.format('moet %s zijn maar was %s', lenc(val), lenc(res)))
		print('Im:')
		for i,ins in ipairs(im) do
			print(combineer(ins))
		end
		print('Lua:')
		print(lua)
	end
end


-- (- 1)
local a = imparse [[
	put 1
	-
]]
verwacht(a, -1)


-- 1 + 2
local a = imparse [[
	put 1
	push 2
	+
]]
verwacht(a, 3)


-- 1 · 2 + 3
local a = imparse [[
	put 1
	push 2
	+
	push 3
	·
]]
verwacht(a, 9)


-- ((-) ∘ (-))(1) = 1
local a = imparse [[
	put -
	push -
	∘
	push 1
	_f
]]
verwacht(a, 1)


-- ((-) ∘ (-))(1) = 1
local a = imparse [[
	put fn.id
	push 1
	_f
]]
verwacht(a, 1)

