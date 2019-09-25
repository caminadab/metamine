require 'stroom'
require 'exp'

local moes = expmoes

local typemt = {}

-- maak nieuw type!
function maaktype(exp, tg)
	assert(tg, 'geen typegraaf')
	if type(exp) == 'string' then exp = ontleedexp(exp) end
	check(exp)
	exp.tg = tg
	return setmetatable(exp, typemt)
end


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
		if other.v == self.f.v then
			return true
		end
	end
end

typemt.__index = {}

function typemt.__index:issubtype(ander)
	if type(ander) == 'string' then
		ander = maaktype(X(ander), self.tg)
	elseif not ander.tg then
		ander.tg = self.tg
	end
	return self.tg:issubtype(self, ander)
end

function typemt.__index:paramtype(ander)
	if type(ander) == 'string' then
		ander = maaktype(X(ander), self.tg)
	elseif not ander.tg then
		ander.tg = self.tg
	end
	return self.tg:paramtype(self, ander)
end
local metatypegraaf = {}

function metatypegraaf:maaktype(exp)
	if type(exp) == 'string' then exp = ontleedexp(exp) end
	check(exp)
	exp.tg = self
	return setmetatable(exp, typemt)
end
	

-- superset
function metatypegraaf:unie(a, b)
	if isatoom(a) and isatoom(b) then
		if self:issubtype(a, b) then
			return b
		elseif self:issubtype(b, a) then
			return a
		else
			return self:maaktype(X'fout', self)
		end
	end
	if isobj(a) and isobj(b) then
		if obj(a) ~= obj(b) then
			return maaktype(X'verzameling', self)
		else
			local t = {o = a.o}
			for i=1,#a do
				t[i] = self:unie(a[i], b[i])
				if not t[i] then
					t[i] = X'iets'
				end
			end
			return t
		end
	end
	return maaktype(X'fout', self)
end

-- subset
function metatypegraaf:intersectie(a, b)
	assert(a)
	assert(b)
	--print('intersectie', combineer(a), combineer(b))
	if isatoom(a) and isatoom(b) then
		if self:issubtype(a, b) then
			return a
		elseif self:issubtype(b, a) then
			return b
		else
			return false
		end
	end
	if isfn(a) and atoom(b) == '→' then return a end
	if isfn(b) and atoom(a) == '→' then return b end
	if isfn(a) and isfn(b) and fn(a) == fn(b) then
		local arg = self:intersectie(a.a, b.a)
		return X(fn(a), arg)
	end
	if isobj(a) and isobj(b) then
		if obj(a) ~= obj(b) or #a ~= #b then
			return false
		else
			local t = {o = a.o}
			for i=1,#a do
				t[i] = self:intersectie(a[i], b[i])
				if not t[i] then
					return false
				end
			end
			return t
		end
	end
	return a
end

-- paramtype('tekst', 'lijst') = 'teken'
function metatypegraaf:paramtype(type, paramtype)
	local doel = moes(type)
	while doel do
		--print('PARAMTYPE', doel, _G.type(doel))
		local t = self.types[doel]
		assert(t, 'geen type voor '..doel)
		if paramtype and t.f and moes(t.f) == moes(paramtype) then
			return table.unpack(t)
		end
		local nieuwdoel = nil
		for pijl in self.graaf:naar(doel) do
			local bron = next(pijl.van)
			nieuwdoel = bron
		end
		doel = nieuwdoel
	end
	do return X'iets' end
	error('geen param gevonden voor type '..exp2string(paramtype))
end

function metatypegraaf:issubtype(type, super)
	if moes(type) == moes(super) then return true end

	if self.graaf:stroomopwaarts(moes(super), moes(type)) then
		return true
	end

	if tonumber(type.v) and fn(super) == '..' then
		local n = tonumber(type.v)
		local min = tonumber(super[1].v)
		local max = tonumber(super[2].v)
		if min <= n and n < max then
			return true
		else
			return false
		end
	end

	if obj(type) == ',' and obj(super) == ',' then
		local alle = true
		for i=1,#type do
			if not self:issubtype(type[i], super[i]) then
				alle = false
				break
			end
		end
		return alle
	end

	-- (1..1000) : (..)
	if isatoom(super) and isfn(type) then
		if super.v == type.f.v then
			return true
		end

	-- moeilijk gaan doen
	elseif isfn(type) and isfn(super) and self:issubtype(type.f, super.f) then -- and moes(type.f) == moes(super.f) then
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
		type = maaktype(type, self)
	end
	--print('LINK', type)
	local super = super or self.iets
	local supermoes, typemoes
	typemoes = moes(type)
	supermoes = moes(super)
	if self.types[typemoes] then
		self.graaf:link(set(typemoes), supermoes)
		self.types[typemoes] = type
		self.types[supermoes] = super
		return
	end
	if not self.types[typemoes] and fn(super) == '_' then
		self:link(super, super.a[1])
		--print('LINK', combineer(super), combineer(super.a[1]))
		self.types[typemoes] = type
		self.types[supermoes] = super
		self:link(type, super)
	end
	if not self.types[supermoes] then
		-- auto
		if fn(super) == '_' then -- and (fn(super.a[1]) == 'lijst' or fn(super.a[1]) == 'set' or fn(super.a[1]) == 'tupel') then
			super = self:link(super, super.a[1])
			--print('LINK', combineer(super), combineer(super.a[1]))
		else
			--print(supermoes)
			super = self:link(super, self.iets)
		end
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

-- typegraaf:
--   types: moes → type
--   graaf: stroom(moes)
function maaktypegraaf()
	local t = {}
	t.graaf = stroom()
	t.iets = maaktype('iets', t)
	t.niets = maaktype('niets', t)
	t.types = {iets = t.iets, niets = t.niets}

	function __tostring(t)
		return t.graaf:tekst()
	end

	t = setmetatable(t, {__index=metatypegraaf,__tostring=__tostring})

	return t
end
