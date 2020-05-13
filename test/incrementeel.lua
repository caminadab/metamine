require 'util'

local files = io.popen('ls test/ex/')

local function assert(cond, msg)
	if not cond then
		print(msg)
	end
end


opt = {['0'] = true}
for pad in files:lines() do
	local moetzijn = pad:match('[^.]*')
	local moetzijn = tonumber(moetzijn)
	print(moetzijn)
	local code = file('test/ex/'..pad)
	local icode = vertaal(code) 
	local ok, is =  pcall(doe, icode)
	assert(ok, is)
	if ok then
		assert(lenc(is) == lenc(moetzijn), 'waarde was '..is..' maar moest '..moetzijn..' zijn')
	end
end

opt = {['0'] = false}
for pad in files:lines() do
	local moetzijn = pad:match('[^.]*')
	local moetzijn = tonumber(moetzijn)
	print(moetzijn)
	local code = file('test/ex/'..pad)
	local icode = vertaal(code) 
	local is =  doe(icode)
	assert(lenc(is) == lenc(moetzijn), '(geoptimaliseerd) waarde was '..is..' maar moest '..moetzijn..' zijn')
end
