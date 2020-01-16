require 'combineer'
require 'symbool'
require 'stroom'
require 'fout'
require 'exp'

-- makkelijke symbolen
local obj2sym = {
	[','] = symbool.tupel,
	['[]'] = symbool.lijst,
	['{}'] = symbool.set,
	--['[]u'] = symbool.tekst,
	['[]u'] = X('_', 'lijst', 'teken'),
}

-- protometatypegraaf
local metatypegraaf = {}

-- impropere subtype
function metatypegraaf:issubtype(type, super)
	if moes(type) == moes(super) then return true end

	-- ontologisch
	if atoom(type) == 'iets' then
		if atoom(super) == 'iets' then
			return true
		else
			return false
		end
	elseif atoom(super) == 'iets' then
		return true
	end

	if self.graaf:stroomafwaarts(moes(type), moes(super)) then
		return true
	end

	-- lijst_int : lijst
	if isfn(type) and atoom(super) == atoom(arg0(type)) then
		return true
	end

	-- a → b : functie
	if fn(type) == '→' and atoom(super) == 'functie' then
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
		if #type ~= #super then
			return false
		end
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
			--return true
		end

	-- moeilijk gaan doen
	elseif isfn(type) and isfn(super) and self:issubtype(type.f, super.f) then -- and moes(type.f) == moes(super.f) then
		return self:issubtype(type.a, super.a)
	end

	return false
end

function metatypegraaf:maaktype(type, super)
	assert(type)
	if _G.type(type) == 'string' then type = ontleedexp(type) end
	if _G.type(super) == 'string' then super = ontleedexp(super) end
	if self.types[moes(type)] then return self.types[moes(type)] end
	--print('LINK', type)

	if not super and fn(type) == '→' then super = X'functie' end
	if not super and obj(type) == ',' then super = X'tupel' end
	if not super and obj(type) == '[]' then super = X'lijst' end
	if not super and obj(type) == '{}' then super = X'set' end
  
	local super = super or X'iets' --self.iets
	local supermoes, typemoes
	typemoes = moes(type)
	supermoes = moes(super)
	if self.types[typemoes] then
		self.graaf:link(set(supermoes), typemoes)
		self.types[typemoes] = type
		self.types[supermoes] = super
		return self.types[typemoes]
	end
	if not self.types[typemoes] and fn(super) == '_' then
		self:maaktype(super, super.a[1])
		--print('LINK', combineer(super), combineer(super.a[1]))
		self.types[typemoes] = type
		self.types[supermoes] = super
		self:maaktype(type, super)
	end
	if not self.types[supermoes] then
		-- auto
		if fn(super) == '_' then -- and (fn(super.a[1]) == 'lijst' or fn(super.a[1]) == 'set' or fn(super.a[1]) == 'tupel') then
			super = self:maaktype(super, super.a[1])
			--print('LINK', combineer(super), combineer(super.a[1]))
		else
			--print(supermoes)
			super = self:maaktype(super, self.iets)
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
		--self.graaf:link(set(moes(type)), moes(b))
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

-- superset
-- destructief voor a (dat moet!)
function metatypegraaf:unie(a, b)
	if isatoom(a) and isatoom(b) then
		if self:issubtype(a, b) then
			return b
		elseif self:issubtype(b, a) then
			return a
		else
			return self:maaktype('fout')
		end
	end
	if isobj(a) and isobj(b) then
		if obj(a) ~= obj(b) then
			return self:maaktype(X'verzameling')
		else
			for i=1,#a do
				a[i] = self:unie(a[i], b[i])
				if not a[i] then
					a[i] = X'iets'
				end
			end
			return a
		end
	end
	if isfn(a) and fn(a) == fn(b) then
		a.a = self:unie(a.a, b.a)
		return a
	end
		
	return self:maaktype('iets')
end

-- subset
-- destructief voor a (dat moet!)
function metatypegraaf:intersectie(a, b, exp)
	assert(a)
	assert(b)
	assert(exp)

	if isatoom(a) and isatoom(b) then
		if self:issubtype(a, b) then
			return a
		elseif self:issubtype(b, a) then
			assign(a, b)
			return a
		else
			--print(self)
			--error(combineer(a)..','..combineer(b))
			local fout = typeerfout(exp.loc,
					'{code} is {exp} maar moet {exp} zijn',
					bron(exp), a, b)
			return false, fout
		end
	end

	-- functie
	if fn(a) == '→' and atoom(b) == 'functie' then return a end
	if fn(b) == '→' and atoom(a) == 'functie' then assign(a, kopieer(b)) ; return a end
	if isfn(a) and fn(a) == fn(b) then
		local sub = exp.a
		if not sub then
			sub = X(C(exp))
			sub.loc = exp.loc
		end
		local aa, fout = self:intersectie(a.a, b.a, sub)
		if aa then
			assign(a.a, aa)
      return a
    else
      return false, fout
    end
	end

	if atoom(a) == 'iets' then
		return assign(a, b)
	elseif atoom(b) == 'iets' then
		return a
	end

	if (isatoom(a) and not isatoom(b)) or (not isatoom(a) and isatoom(b)) then
		local fout = typeerfout(exp.loc,
			'{code} is {exp} maar moet {exp} zijn',
			bron(exp), a, b)
		return false, fout
	end

	if isobj(a) and isobj(b) then
		--error('ok')
		if obj(a) ~= obj(b) or #a ~= #b then
			local fout = typeerfout(exp.loc,
					'{code} is {exp} maar moet {exp} zijn!!!',
					bron(exp), a, b)
			return false, fout

		else
			for i=1,#a do
				assert(a[i])
				assert(b[i])
				--assert(exp[i], 'geen exp['..i..'] voor '..combineer(exp))
				local sub = exp[i]
				if not sub then
					sub = X(i..'e argument van '..C(exp))
					sub.loc = exp.loc
				end

				local ins, fout = self:intersectie(a[i], b[i], sub)

				if not ins then
					return false, fout
				end

				assign(a[i], ins)
				assign(b[i], ins)
				--a[i] = ins
				--b[i] = ins
			end
			return a
		end

	end

	-- triviaal
	if self:issubtype(a, b) then return a end
	if self:issubtype(b, a) then assign(a, kopieer(b)) ; return a end

	local fout = typeerfout(exp.loc,
		'{code} is {exp} maar moet {exp} zijn',
		bron(exp), a, b)

	return false, fout
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

-- typegraaf:
--   types: moes → type
--   graaf: stroom(moes)
function maaktypegraaf()
	local function tostring(t)
		return t.graaf:tekst()
	end

	local t = setmetatable({}, {__index=metatypegraaf,__tostring=tostring})
	t.types = {iets = X'iets', niets = X'niets'}
	t.iets = t.types.iets
	t.niets = t.types.niets
	t.graaf = maakstroom()
	t.graaf:punt('iets')
	t.graaf:punt('niets')

	return t
end
