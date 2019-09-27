require 'typegraaf'
require 'rapport'
require 'ontleed'
require 'util'
require 'typeer'

-- laat graaf zien in browser
function laatzien(graaf, naam)
	file('.graaf.html', graaf2html(graaf, naam or 'Graaf'))
	os.execute('chromium .graaf.html')
	os.remove('.graaf.html')
end

-- int ⊂ getal
do 
	local g = maaktypegraaf()
	local getal = g:maaktype('getal', 'iets')
	local int = g:maaktype('int', 'getal')

	if not g:issubtype(int, getal) then
		print('"int" is geen subset van "getal"')
		print('int ⊂ getal = ', g.graaf:stroomafwaarts('int', 'getal'))
		print('getal ⊂ int = ', g.graaf:stroomafwaarts('getal', 'int'))
		laatzien(g.graaf, 'int ⊂ getal ⊂ iets')
		assert(false)
	end
end

-- simpel tupel
do
	local g = maaktypegraaf()
	g:maaktype('getal')
	local a = g:maaktype('(iets, getal)')
	local b = g:maaktype('(getal, getal)')
	if not g:issubtype(b, a) then
		laatzien(g.graaf, 'int ⊂ getal ⊂ iets')
		assert(false)
	end
end

-- tuple destructuring
do
	local g = maaktypegraaf()
	g:maaktype('getal')
	local a = g:maaktype('(iets, getal)')
	local b = g:maaktype('((getal, getal), getal)')
	if not g:issubtype(b, a) then
		laatzien(g.graaf, '((getal, getal) → getal) ⊂ (iets, getal) ⊂ iets')
	end
end

-- diamant
do
	local g = maaktypegraaf()
	local getal = g:maaktype('getal')
	local int = g:maaktype('int', 'getal')
	local gg = g:maaktype('(getal, getal)')
	local ig = g:maaktype('(int,   getal)')
	local gi = g:maaktype('(getal, int)')
	local ii = g:maaktype('(int,   int)')

	function passert(cnd, msg)
		if not cnd then laatzien(g.graaf, 'Diamanttest') end
		assert(cnd, msg)
	end

	passert(not g:issubtype(ii, gg), 'Diamanttest faalde')
	-- TODO :)
	--[[
	passert(g:issubtype(ig, gg))
	passert(g:issubtype(gi, gg))
	passert(not g:issubtype(gg, ii), combineer(gg)..' : '..combineer(ii))
	passert(not g:issubtype(ig, gi), combineer(ig)..' : '..combineer(gi))
	passert(not g:issubtype(gi, ig), combineer(gi)..' : '..combineer(ig))
	]]

end
