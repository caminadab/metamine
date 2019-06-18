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

function substitueerzuinig(exp, van, naar, maakvar, al)
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
			error('UHH')
			ref = X('~' .. maakvar())
		end
		van.exp = ref
		naar.ref = ref
	end

	if isexp(naar) and al[moes(van)] then
		ret = al[moes(van)]
		--al[moes(van)] = ref

	elseif isatoom(exp) then
		if exp.v == van.v then
			if isexp(naar) then
				al[moes(van)] = ref
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
				error'RAAR'
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
		t.ref = exp.ref
		ret = t
	end
	--van.ref = ref

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
	local b = substitueerzuinig(a, X'a', s)
	local _, tel = string.gsub(moes(b), "/", "")
	assert(tel == 1, e2s(b))
	assert(b[2].exp == s)
end
