require 'deparse'
require 'symbol'
require 'flow'
require 'fout'
require 'exp'

-- makkelijke symbolen
local obj2sym = {
	[','] = symbol.tupel,
	['[]'] = symbol.lijst,
	['{}'] = symbol.set,
	--['[]u'] = symbol.text,
	['[]u'] = X('_', 'lijst', 'teken'),
}

-- protometatypegraph
local metatypegraph = {}

-- impropere subtype
function metatypegraph:issubtype(type, super)
	if hash(type) == hash(super) then return true end

	-- ontologisch
	if atom(type) == 'iets' then
		if atom(super) == 'iets' then
			return true
		else
			return false
		end
	elseif atom(super) == 'iets' then
		return true
	end

	if self.graph:flowafwaarts(hash(type), hash(super)) then
		return true
	end

	-- lijst_int : lijst
	if isfn(type) and atom(super) == atom(arg0(type)) then
		return true
	end

	-- a → b : functie
	if fn(type) == '→' and atom(super) == 'functie' then
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
	if isatom(super) and isfn(type) then
		if super.v == type.f.v then
			--return true
		end

	-- moeilijk gaan doen
	elseif isfn(type) and isfn(super) and self:issubtype(type.f, super.f) then -- and hash(type.f) == hash(super.f) then
		return self:issubtype(type.a, super.a)
	end

	return false
end

function metatypegraph:maaktype(type, super)
	assert(type)
	if _G.type(type) == 'string' then type = parseexp(type) end
	if _G.type(super) == 'string' then super = parseexp(super) end
	if self.types[hash(type)] then return self.types[hash(type)] end
	--print('LINK', type)

	if not super and fn(type) == '→' then super = X'functie' end
	if not super and obj(type) == ',' then super = X'tupel' end
	if not super and obj(type) == '[]' then super = X'lijst' end
	if not super and obj(type) == '{}' then super = X'set' end
  
	local super = super or X'iets' --self.iets
	local superhash, typehash
	typehash = hash(type)
	superhash = hash(super)
	if self.types[typehash] then
		self.graph:link(set(superhash), typehash)
		self.types[typehash] = type
		self.types[superhash] = super
		return self.types[typehash]
	end
	if not self.types[typehash] and fn(super) == '_' then
		self:maaktype(super, super.a[1])
		--print('LINK', deparse(super), deparse(super.a[1]))
		self.types[typehash] = type
		self.types[superhash] = super
		self:maaktype(type, super)
	end
	if not self.types[superhash] then
		-- auto
		if fn(super) == '_' then -- and (fn(super.a[1]) == 'lijst' or fn(super.a[1]) == 'set' or fn(super.a[1]) == 'tupel') then
			super = self:maaktype(super, super.a[1])
			--print('LINK', deparse(super), deparse(super.a[1]))
		else
			--print(superhash)
			super = self:maaktype(super, self.iets)
		end
	end
	super = assert(self.types[superhash], superhash)

	-- vind bovengrens
	local a = super
	local beter = true
	while beter do
		beter = false
		for pijl in self.graph:van(hash(a)) do
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
	for pijl in self.graph:van(hash(a)) do
		local asub = self.types[pijl.naar]

		if self:issubtype(asub, type) then
			--print('  B ISSUB')
			b = asub
			bpijl = pijl
			break -- TODO wat als er meer dan 1 is
		end
	end

	--print('LINK', hash(a), b and hash(b))

	if b then
		self.graph:ontlink(bpijl)
		--self.graph:link(set(hash(type)), hash(b))
	end

	self.graph:link(set(hash(a)), hash(type))
	self.types[hash(type)] = type
	
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
function metatypegraph:unie(a, b)
	if isatom(a) and isatom(b) then
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
function metatypegraph:intersectie(a, b, exp)
	assert(a)
	assert(b)
	assert(exp)

	if isatom(a) and isatom(b) then
		if self:issubtype(a, b) then
			return a
		elseif self:issubtype(b, a) then
			assign(a, b)
			return a
		else
			--print(self)
			--error(deparse(a)..','..deparse(b))
			local fout = typifyfout(exp.loc,
					'{code} is {exp} maar moet {exp} zijn',
					bron(exp), a, b)
			return false, fout
		end
	end

	if obj(a) == ',' and fn(b) == '→' then
		return a
	end
	if obj(b) == ',' and fn(a) == '→' then
		assign(a, b)
		return a
	end

	-- functie
	if fn(a) == '→' and atom(b) == 'functie' then return a end
	if fn(b) == '→' and atom(a) == 'functie' then assign(a, copy(b)) ; return a end
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

	if atom(a) == 'iets' then
		return assign(a, b)
	elseif atom(b) == 'iets' then
		return a
	end

	if (isatom(a) and not isatom(b)) or (not isatom(a) and isatom(b)) then
		local fout = typifyfout(exp.loc,
			'{code} is {exp} maar moet {exp} zijn',
			bron(exp), a, b)
		return false, fout
	end

	if isobj(a) and isobj(b) then
		--error('ok')
		if obj(a) ~= obj(b) or #a ~= #b then
			local fout = typifyfout(exp.loc,
					'{code} is {exp} maar moet {exp} zijn',
					bron(exp), a, b)
			return false, fout

		else
			for i=1,#a do
				assert(a[i])
				assert(b[i])
				--assert(exp[i], 'geen exp['..i..'] voor '..deparse(exp))
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
	if self:issubtype(b, a) then assign(a, copy(b)) ; return a end

	local fout = typifyfout(exp.loc,
		'{code} is {exp} maar moet {exp} zijn',
		bron(exp), a, b)

	return false, fout
end

-- paramtype('text', 'lijst') = 'teken'
function metatypegraph:paramtype(type, paramtype)
	local doel = hash(type)
	while doel do
		--print('PARAMTYPE', doel, _G.type(doel))
		local t = self.types[doel]
		assert(t, 'geen type voor '..doel)
		if paramtype and t.f and hash(t.f) == hash(paramtype) then
			return table.unpack(t)
		end
		local nieuwdoel = nil
		for pijl in self.graph:naar(doel) do
			local bron = next(pijl.van)
			nieuwdoel = bron
		end
		doel = nieuwdoel
	end
	do return X'iets' end
	error('geen param gevonden voor type '..exp2string(paramtype))
end

-- typegraph:
--   types: hash → type
--   graph: flow(hash)
function maaktypegraph()
	local function tostring(t)
		return t.graph:text()
	end

	local t = setmetatable({}, {__index=metatypegraph,__tostring=tostring})
	t.types = {iets = X'iets', niets = X'niets'}
	t.iets = t.types.iets
	t.niets = t.types.niets
	t.graph = maakflow()
	t.graph:punt('iets')
	t.graph:punt('niets')

	return t
end
