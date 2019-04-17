require 'stroom'
require 'exp'

local moes = exphash

local typemt = {}

function typemt:__eq(other)
	return moes(self) == moes(other)
end

function typemt:__tostring()
	return exp2string(self)
end

-- is subtype?
-- alleen f(...) : f
function typemt:__lt(other)
	if isatoom(other) and isfn(self) then
		if other.v == self.fn.v then
			return true
		end
	end
end

local metatypegraaf = {}

function metatypegraaf:issubtype(type, super)
	-- naar beneden
	if type < super then
		return true

	-- moeilijk gaan doen
	elseif isfn(type) and isfn(super) and moes(type.fn) == moes(super.fn) then
		assert(#type == #super)
		local issub = true
		for i=1,#type do
			local akind = super[i]
			local tkind = type[i]
			if moes(akind) ~= moes(tkind) and not self.graaf:stroomopwaarts(moes(akind), moes(tkind)) then
				issub = false
			end
		end
		return issub
	end

	return false
end

function metatypegraaf:link(type, super)
	--print('LINK', type)
	local super = super or self.iets
	local supermoes, typemoes
	typemoes = moes(type)
	supermoes = moes(super)
	super = assert(self.types[supermoes], supermoes)

	-- vind bovengrens
	local a = super
	local beter = true
	while beter do
		beter = false
		for pijl in self.graaf:van(moes(a)) do
			local asub = self.types[pijl.naar]

			--print('  ISSUB', type, asub)
			if self:issubtype(type, asub) then
				--print('    JA')
				a = asub
				beter = true
				break
			else
				--print('    NEE')
			end

		end
	end

	--print('  A = '..tostring(a))

	-- zoek ondergrens
	local b, bpijl
	for pijl in self.graaf:van(moes(a)) do
		local asub = self.types[pijl.naar]

		if self:issubtype(asub, type) then
			--print('  B ISSUB')
			b = asub
			bpijl = pijl
			break -- TODO wat als er meer dan 1 is
		end
	end

	if b then
		self.graaf:ontlink(bpijl)
		self.graaf:link(set(moes(type)), moes(b))
	end

	self.graaf:link(set(moes(a)), moes(type))
	self.types[moes(type)] = type
	
	--for pijl in s:van(a) do
	--	local b = pijl.naar
	--	if 

	--if self.punten[t] then

	--else
	--	s:link(a, t)
	--end

	return type
end

function maaktype(exp)
	if type(exp) == 'string' then exp = ontleedexp(exp) end
	if not exp.fn and not exp.v then error('arg is geen exp') end
	return setmetatable(exp, typemt)
end

-- typegraaf:
--   types: moes → type
--   graaf: stroom(moes)
function typegraaf()
	local t = {}
	t.graaf = stroom()
	t.iets = maaktype('iets')
	t.types = {[moes(t.iets)] = t.iets}

	function __tostring(t)
		return t.graaf:tekst()
	end

	t = setmetatable(t, {__index=metatypegraaf,__tostring=__tostring})

	-- def
	local getal = t:link(maaktype'getal')
	t:link(maaktype'int', getal)
	t:link(maaktype'kommagetal', getal)
	--g:link(maaktype(O'(..)'), maaktype(O'int'))

	local verzameling = t:link(maaktype'verzameling')
	t:link(maaktype'lijst', verzameling)
	t:link(maaktype'set', verzameling)
	t:link(maaktype'tupel', verzameling)
	t:link(maaktype'(->)')
	t:link(maaktype'(,)')

	return t
end

-- map, fouten
function typeer(exp)
	-- typeafhankelijkheidsgraaf
end

if test then
	require 'ontleed'
	local O = ontleedexp

	local g = typegraaf()
	--[[
	g:link(maaktype('int → int'))
	g:link(maaktype('getal → int'))
	g:link(maaktype('getal → iets'))
	]]
	--g:link(maaktype('lijst int'))
	--g:link(maaktype('lijst getal'))
	g:link(maaktype('norm'), g.types.kommagetal)
	g:link(maaktype('(getal, getal, getal)'))
	g:link(maaktype('(kommagetal, kommagetal, kommagetal)'))
	g:link(maaktype('(norm, norm, norm)'))

	print('Typegraaf')
	print(g)
end
