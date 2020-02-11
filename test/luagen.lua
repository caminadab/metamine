require 'bouw.luagen'
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
	assert(ok, res .. '\n' .. lua)

	assert(res == val, string.format('%s moet %s zijn maar was %s', lua, lenc(val), lenc(res)))
end


-- (- 1)
local a = imparse [[
	push 1
	-
]]
verwacht(a, -1)


-- 1 + 2
local a = imparse [[
	push 1
	push 2
	+
]]
verwacht(a, 3)


-- 1 · 2 + 3
local a = imparse [[
	push 1
	push 2
	+
	push 3
	·
]]
verwacht(a, 9)


-- ((-) ∘ (-))(1) = 1
local a = imparse [[
	push -
	push -
	∘
	push 1
	_
]]
verwacht(a, 1)

