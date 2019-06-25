require 'exp'

function isvar(name)
	if not isatoom(name) then
		return false
	end
	if tonumber(name.v) then
		return false
	elseif name.v == '||' then
		return false
	elseif string.match(name.v, '^%w*$') then
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
		var(exp.fn,c,t)
		for i,v in ipairs(exp) do
			var(v,c,t)
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
			return naar, 1
		else
			return exp, 0
		end
	else
		if isexp(van) then
			if expmoes(exp) == expmoes(van) then
				return naar, 1
			end
		end
		local t = {loc=exp.loc}
		local n = 0
		t.fn = substitueer(exp.fn, van, naar)
		for i,v in ipairs(exp) do
			local m
			t[i],m = substitueer(v, van, naar)
			n = n + m
		end
		return t, n
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
		return exp, 0
	end

	-- hier gaan we!
	local vannen = moezen[moes(van)]

	for i, sub in ipairs(vannen) do
		ontlink(sub, i)
		-- lang uitschrijven
		if i == 1 or isatoom(naar) then
			local ref = van.ref --sub.ref or van.ref
			assign(sub, naar)
			--print('UITSCHRIJF', moes(van), e2s(sub))
			naar.ref = van.ref
			if true or not al[ref.v] then
			--print('REF', ref.v, e2s(naar), isatoom(naar))
			--al[ref.v] = ref
			end

			if not van.ref then
				van.ref = maakref(van)
			end
			ref = van.ref
			sub.ref = ref
			ref.exp = sub
			van.exp = ref
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

function substitueerzuinig0(exp, van, naar, maakvar, al)
	if S then S = S + 1 end
	--do return substitueer(exp, van, naar) end
	--local m = moes(van)..'_'..moes(naar)
	al = al or {}
	local ret

	-- maak ref
	local ref = van.ref
	if not ref then
		if isatoom(van) then
			ref = X('~' .. van.v)
		else
			--error('UHH')
			ref = X('~' .. maakvar())
		end
		--van.exp = ref
		naar.ref = ref
	end

	-- maak ref voor exp
	if not exp.ref then
		-- TODO hoeven atomen inderdaad geen referentie?
		if isatoom(exp) then
			if false then
				exp.ref = X('~' .. exp.v)
			end
		else
			--error('UHH')
			exp.ref = X('~' .. maakvar())
		end
		van.exp = ref
		naar.ref = ref
	end

	if isatoom(exp) then
		if al[moes(van)] and exp.v == van.v then
			al[moes(van)] = ref
			ret = al[moes(van)]
			--ret.ref = assert(ref)

		elseif exp.v == van.v then
			if isexp(naar) then
				al[moes(van)] = assert(ref)
			--naar.ref = assert(ref)
				--print(ret, naar)
			end
			ret = naar
			naar.ref = ref
		else
			ret = exp

		end

	else

		if isexp(van) then
			if moes(exp) == moes(van) then
				--error'RAAR'
				naar.ref = exp.ref
				return naar, 1
			end
		end

		local t = {loc=exp.loc}
		local n = 0
		t.fn = substitueerzuinig(exp.fn, van, naar, maakvar, al)
		for i,v in ipairs(exp) do
			t[i] = substitueerzuinig(v, van, naar, maakvar, al)
		end
		--t.ref = X('~'..maakvar())
		t.ref = assert(exp.ref, 'exp heeft geen ref: '..moes(exp))
		ret = t
	end
	--van.ref = ref

	--al[moes(van)] = ref

	return assert(ret, 'niet ret')
end

sym = {}

sym.plus = X'+'
sym.min = X'-'
sym.keer = X'*'
sym.deel = X'/'
sym.plusis = X'+='
sym.minis = X'-='
sym.keeris = X'*='
sym.deelis = X'/='

sym.alt = X'|'
sym.altis = X'|='
sym.call = X'call'
sym.cat = X'||'
sym.catass = X'||='
sym.co = X'co'
sym.cois = X'co='
sym.dan = X'=>'
sym.als = X'=>'
sym.niet = X'!'
sym.niets = X'niets'
sym.lijst = X'[]'
sym.is = X'='
sym.oud = X"'"
sym.ass = X':='
sym.map = X'->'
sym.maplet = X'-->'
sym.start = X'start'
sym.set = X'{}'
sym.stop = X'stop'

if test then
	local a = X('+', 'a', 'a')
	local s = X('/', '1', '2')
	local b = substitueerzuinig(a, X'a', s, maakvars())
	local _, tel = string.gsub(moes(b), "/", "")
	assert(tel == 1, moes(b))
	--assert(b[2].exp == s, e2s(b))
end
