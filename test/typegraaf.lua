require 'typegraph'
require 'rapport'
require 'parse'
require 'util'
require 'typify'

-- laat graph zien in browser
function laatzien(graph, name)
	file('.graph.html', graph2html(graph, name or 'Graaf'))
	os.execute('chromium .graph.html >/dev/null 2>/dev/null')
	os.remove('.graph.html')
end

-- int ⊂ getal
do 
	local g = maaktypegraph()
	local getal = g:maaktype('getal', 'iets')
	local int = g:maaktype('int', 'getal')

	if not g:issubtype(int, getal) then
		print('"int" is geen subset van "getal"')
		print('int ⊂ getal = ', g.graph:flowafwaarts('int', 'getal'))
		print('getal ⊂ int = ', g.graph:flowafwaarts('getal', 'int'))
		laatzien(g.graph, 'int ⊂ getal ⊂ iets')
		assert(false)
	end
end

-- simpel tupel
do
	local g = maaktypegraph()
	g:maaktype('getal')
	local a = g:maaktype('(iets, getal)')
	local b = g:maaktype('(getal, getal)')
	if not g:issubtype(b, a) then
		laatzien(g.graph, 'int ⊂ getal ⊂ iets')
		assert(false)
	end
end

-- tuple destructuring
do
	local g = maaktypegraph()
	g:maaktype('getal')
	local a = g:maaktype('(iets, getal)')
	local b = g:maaktype('((getal, getal), getal)')
	if not g:issubtype(b, a) then
		laatzien(g.graph, '((getal, getal) → getal) ⊂ (iets, getal) ⊂ iets')
	end
end

-- diamant
do
	local g = maaktypegraph()
	local getal = g:maaktype('getal')
	local int = g:maaktype('int', 'getal')
	local gg = g:maaktype('(getal, getal)')
	local ig = g:maaktype('(int,   getal)')
	local gi = g:maaktype('(getal, int)')
	local ii = g:maaktype('(int,   int)')

	function passert(cnd, msg)
		if not cnd then laatzien(g.graph, msg) end
		assert(cnd, msg)
	end

	passert(g:issubtype(ii, gg), 'Diamanttest')
	-- TODO :)
	--[[
	passert(g:issubtype(ig, gg))
	passert(g:issubtype(gi, gg))
	passert(not g:issubtype(gg, ii), deparse(gg)..' : '..deparse(ii))
	passert(not g:issubtype(ig, gi), deparse(ig)..' : '..deparse(gi))
	passert(not g:issubtype(gi, ig), deparse(gi)..' : '..deparse(ig))
	]]
end

-- functietype
do
	local g = maaktypegraph()
	local getal = g:maaktype 'getal'
	local int = g:maaktype ('int', 'getal')
	local fn = g:maaktype 'iets → iets'
	local ii = g:maaktype 'int → int'
	local gg = g:maaktype 'getal → getal'
	assert(g:issubtype(ii, fn))
	assert(g:issubtype(gg, fn))
	assert(g:issubtype(ii, gg))
end

-- lijst
do
	local g = maaktypegraph()
	local intlijst = g:maaktype 'lijst int'
	local lijst = g:maaktype 'lijst'
	if not g:issubtype(intlijst, lijst) then
		laatzien(g.graph, 'lijst(int) ⊂ lijst')
	end
end

-- text
if false then
	local g = maaktypegraph()
	local text = g:maaktype 'text'
	local letterlijst = g:maaktype 'lijst(letter)'
	if not g:issubtype(text, letterlijst) then
		laatzien(g.graph, 'text ⊂ lijst(letter)')
	end
end


-- intersectie
do
	local g = maaktypegraph()
	local ii = g:maaktype 'iets → iets'
	local ins = g:intersectie(g.iets, ii, X'TEST', X'TEST')
	assert(hash(ins) == hash(ii), hash(ins)..' ≠ '..hash(ii))
end

-- functie basistype
do
	local g = maaktypegraph()
	local fn = g:maaktype 'functie'
	local getal = g:maaktype 'getal'
	local int = g:maaktype ('int', 'getal')
	local uu = g:maaktype ('iets → iets', 'functie')
	local gu = g:maaktype ('getal → iets')
	local gu = g:maaktype ('int → int')
	local gu = g:maaktype ('getal → int')
	--laatzien(g.graph)
	assert(g:issubtype(uu, fn))
	assert(g:issubtype(gu, uu))
	assert(g:issubtype(gu, fn))
end

-- functie fouten
do
	local g = maaktypegraph()
	local fn = g:maaktype 'functie'
	local sin = g:maaktype 'getal → getal'
	local cirkel = g:maaktype 'lijst → getal'
	assert(not g:issubtype(sin, cirkel))
	assert(not g:issubtype(cirkel, sin))
	assert(not g:intersectie(sin, cirkel, X'ok'))
end

-- false
if false then
	local g = maaktypegraph()
	linklib(g)
	laatzien(g.graph)
end
