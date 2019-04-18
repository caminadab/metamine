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

function metatypegraaf:unie(a, b)
	if isatoom(a) and isatoom(b) then
		if self:issubtype(a, b) then
			return a
		elseif self:issubtype(b, a) then
			return b
		else
			return false
		end
	end
	local t = {fn = self:unie(a.fn or a, b.fn or b)}
	if not t.fn then return false end
	for i=1,math.max(#a, #b) do
		if a[i] and b[i] then
			t[i] = self:unie(a[i], b[i])
		else
			t[i] = a[i] or b[i]
		end
	end
	return t
end

function metatypegraaf:issubtype(type, super)
	if moes(type) == moes(super) then return true end
	if self.graaf:stroomopwaarts(moes(super), moes(type)) then
		return true
	end

	-- (1..1000) : (..)
	if isatoom(super) and isfn(type) then
		if super.v == type.fn.v then
			return true
		end

	-- moeilijk gaan doen
	elseif isfn(type) and isfn(super) and self:issubtype(type.fn, super.fn) then -- and moes(type.fn) == moes(super.fn) then
		if #super ~= #type then return false end
		--assert(#type == #super, "Type = "..moes(type)..", Super = "..moes(super))
		local issub = true
		for i=1,#type do
			local skind = super[i]
			local tkind = type[i]
			if moes(skind) ~= moes(tkind) and not self.graaf:stroomopwaarts(moes(skind), moes(tkind)) then
				--print('NIET, vanwege '..moes(skind)..' < '..moes(tkind))
				issub = false
			end
		end
		return issub
	end

	return false
end

function metatypegraaf:link(type, super)
	if self.types[moes(type)] then return end
	if not getmetatable(type) then
		type = maaktype(type)
	end
	--print('LINK', type)
	local super = super or self.iets
	local supermoes, typemoes
	typemoes = moes(type)
	supermoes = moes(super)
	if not self.types[supermoes] then
		super = self:link(super, self.iets)
	end
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

	--print('LINK', moes(a), b and moes(b))

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
function maaktypegraaf()
	local t = {}
	t.graaf = stroom()
	t.iets = maaktype 'iets'
	t.niets = maaktype 'niets'
	t.types = {iets = t.iets, niets = t.niets}

	function __tostring(t)
		return t.graaf:tekst()
	end

	t = setmetatable(t, {__index=metatypegraaf,__tostring=__tostring})

	return t
end

if test then
	require 'ontleed'
	local O = ontleedexp

	local g = maaktypegraaf()
	--[[
	g:link(maaktype('int → int'))
	g:link(maaktype('getal → int'))
	g:link(maaktype('getal → iets'))
	]]
	--g:link(maaktype('lijst int'))
	--g:link(maaktype('lijst getal'))
	local getal = g:link(maaktype 'getal')
	g:link(maaktype('int'), getal)
	local verzameling = maaktype 'verzameling'
	g:link(maaktype'lijst', verzameling)
	g:link(maaktype('lijst int'))
	g:link(maaktype('lijst getal'))
	--g:link(maaktype('verzameling getal'))

	print('Typegraaf')
	print(g)
end
