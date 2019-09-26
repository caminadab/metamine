require 'typegraaf'
require 'rapport'
require 'ontleed'
require 'util'
require 'typeer'

local g = maaktypegraaf()
--linkbieb(g)

local int = g:maaktype('int', 'getal')
local getal = g:maaktype('getal', 'iets')

if not g:issubtype(int, getal) then
	print('"int" is geen subset van "getal"')
	print('int ⊂ getal = ', g.graaf:stroomafwaarts('int', 'getal'))
	print('getal ⊂ int = ', g.graaf:stroomafwaarts('getal', 'int'))
	file('graaf.html', graaf2html(g.graaf, 'int : getal : iets'))
	os.execute('chromium graaf.html')
	return
end

local g = maaktypegraaf()
g:maaktype('getal')
local a = g:maaktype('(iets, getal)')
local b = g:maaktype('(getal, getal)')
if not g:issubtype(b, a) then
	file('graaf.html', graaf2html(g.graaf, 'int : getal : iets'))
	os.execute('chromium graaf.html')
end

local g = maaktypegraaf()
g:maaktype('getal')
local a = g:maaktype('(iets, getal)')
local b = g:maaktype('((getal, getal), getal)')
if not g:issubtype(b, a) then
	file('graaf.html', graaf2html(g.graaf, 'int : getal : iets'))
	os.execute('chromium graaf.html')
end

if true then
	local g = maaktypegraaf()
	linkbieb(g)
	file('graaf.html', graaf2html(g.graaf, 'int : getal : iets'))
	os.execute('chromium graaf.html')
	do return end
end

-- diamant
do
	local g = maaktypegraaf()
	local getal g:maaktype('getal')
	local int = g:maaktype('int', 'getal')
	local gg = g:maaktype('(getal, getal)')
	local ig = g:maaktype('(int,   getal)')
	local gi = g:maaktype('(getal, int)')
	local ii = g:maaktype('(int,   int)')

	function passert(cnd, msg)
		print(msg or 'assertion failed!')
		file('graaf.html', graaf2html(g.graaf, 'Diamanttest'))
		os.execute('chromium graaf.html')
		assert(false)
	end

	passert(g:issubtype(ii, gg))
	-- TODO :)
	--[[
	passert(g:issubtype(ig, gg))
	passert(g:issubtype(gi, gg))
	passert(not g:issubtype(gg, ii), combineer(gg)..' : '..combineer(ii))
	passert(not g:issubtype(ig, gi), combineer(ig)..' : '..combineer(gi))
	passert(not g:issubtype(gi, ig), combineer(gi)..' : '..combineer(ig))
	]]

end
