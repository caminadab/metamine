require 'exp'

function isvar(name)
	if not isatoom(name) then
		return false
	end
	if tonumber(name.v) then
		return false
	elseif name.v == '||' then
		return false
	elseif string.match(name.v, '^[%w\\.]*$') then
		return true
	end
	return false
end

function var0(exp,t)
	vars = var
	local f = var
	local t = t or {}
	if atom(exp) then
		if isvar(exp) then
			t[exp] = true
		end
	else
		-- SHADUW IS GEEN VAR
		if exp[1] == "'" then
			return t
		end
		for i,s in ipairs(exp) do
			f(s,t)
		end
	end
	return t
end

function var(exp,c,t)
	if not c then c = tonumber end
	local t = t or {}
	if isatoom(exp) then
		if not c(exp) then t[exp] = true end
	else
		for k, sub in subs(exp) do
			var(sub,c,t)
		end
	end
	return t
end
vars = var

function val(exp,t)
	local t = t or {}
	if atom(exp) then
		if isvar(exp) or tonumber(exp) then
			t[exp] = true
		end
	else
		-- SHADUW IS GEEN VAR
		if exp[1] == "'" then
			return t
		end
		for i,s in ipairs(exp) do
			val(s,t)
		end
	end
	return t
end

function substitueer(exp, van, naar)
	if isatoom(exp) then
		if exp.v == van.v then
			naar.ref = van.ref
			return naar
		else
			return exp
		end
	else
		if isfn(van) then
			if moes(exp) == moes(van) then
				naar.ref = van.ref
				return naar
			end
		end
		local t = {loc=exp.loc,o=exp.o,f=exp.f}
		--t.f = substitueer(exp.f, van, naar)
		for k,v in subs(exp) do
			t[k] = substitueer(v, van, naar)
		end
		t.ref = exp.ref
		return t
	end
end

Al = {}
function substitueerzuinig(exp, van, naar, maakvar, al)
	al = Al or al or {}
	local moezen = exp.moezen

	local function maakref(exp)
		-- maak ref
		local ref = exp.ref
		if not ref then
			if isatoom(exp) then
				ref = X('~' .. exp.v)
			else
				ref = X('~' .. maakvar())
			end
			exp.ref = ref
		end
		--print('REF', e2s(exp), ref)
		return ref
	end

	local function link(exp)
		--print('LINK', e2s(exp))
		exp.moes = nil
		local m = moes(exp)
		if not moezen[m] then
			moezen[m] = {}
		end
		-- zitten we er al in?
		if moezen[m][exp] then
			return false
		end
		if not isatoom(exp) then
			exp.ref = maakref(exp)
			--exp.ref.exp = exp
		end
		moezen[m][exp] = true
		table.insert(moezen[m], exp)
	end

	function ontlink(exp, i)
		local m = moes(exp)
		if not moezen[m] then return end
		table.remove(moezen[m], i)
		if #moezen[m] == 0 then moezen[m] = nil end
	end

	--if not naar.ref then naar.ref = maakref(naar) end

	if not moezen then
		moezen = {}
		for sub in boompairsbfs(exp) do
			link(sub)
		end
	end
	exp.moezen = moezen

	if not moezen[moes(van)] then
		return exp
	end

	exp.moes = nil

	-- hier gaan we!
	local vannen = moezen[moes(van)]

	for i, sub in ipairs(vannen) do
		ontlink(sub, i)
		-- lang uitschrijven
		if i == 1 or isatoom(naar) and not naar.v:sub(1,4) == '_arg' then
			local ref = sub.ref or van.ref or naar.ref
			if not ref then
				ref = maakref(van)
			end
			assign(sub, naar)
			--print('UITSCHRIJF', moes(van), moes(sub), e2s(ref))
			sub.ref = ref
			ref.exp = sub
			van.exp = ref
			naar.ref = ref
			for ultrasub in boompairsdfs(sub) do
				ultrasub.moes = nil
				link(ultrasub)
			end

		-- geen referentie!
		elseif not van.ref then
			assign(sub, naar)
			print('geen ref!', e2s(naar))

		-- afkorten
		else
			assign(sub, van.ref)
			--print('AFKORT', moes(van), e2s(sub))
		end

		--print('EXP' ,e2s(exp))
	end
		--print('RET' ,e2s(exp))
	return exp
end

sym = {
	plus = X'+',
	min = X'-',
	keer = X'·',
	deel = X'/',
	plusis = X'+=',
	minis = X'-=',
	keeris = X'·=',
	deelis = X'/=',

	alt = X'|',
	altis = X'|=',
	call = X'call',
	cat = X'‖',
	catass = X'‖=',
	co = X'∐',
	cois = X'∐=',
	dan = X'⇒',
	als = X'⇒',
	niet = X'¬',
	iets = X'iets',
	ja = '⊤',
	niets = X'niets',
	lijst = X'[]',
	is = X'=',
	oud = X"'",
	ass = X':=',
	map = X'→',
	maplet = X'↦',
	start = X'start',
	set = X'{}',
	stop = X'stop',

	bit = X'bit',
	int = X'int',
	getal = X'getal',
	lijst = X'lijst',
	set = X'set',
	tupe = X'tupel',
	tekst = X'tekst',
}
symbool = sym

if test then
	local a = X('+', 'a', 'a')
	local s = X('/', '1', '2')
	local b = substitueerzuinig(a, X'a', s, maakvars())
	local _, tel = string.gsub(moes(b), "/", "")
	assert(tel == 1, moes(b))
	--assert(b[2].exp == s, e2s(b))
end
