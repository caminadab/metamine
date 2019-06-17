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

function substitueerzuinig(exp, van, naar, al, maakvar)
	--do return substitueer(exp, van, naar) end
	local al = al or {}
	local maakvar = maakvar or maakvars()
	if al[moes(exp)] then
		local resnum = al[moes(exp)]
		local ref, num = resnum[1], resnum[2]
		ref.exp.ref = assert(ref.v)
		return ref, num
	end
	local res,num
	if isatoom(exp) then
		if exp.v == van.v then
			res, num = naar, 1
		else
			res, num = exp, 0
		end
	else
		if isexp(van) then
			if expmoes(exp) == expmoes(van) then
				res, num = naar, 1
			end
		end
		local t = {loc=exp.loc}
		local n = 0
		t.fn = substitueerzuinig(exp.fn, van, naar, al, maakvar)
		for i,v in ipairs(exp) do
			local m
			t[i],m = substitueerzuinig(v, van, naar, al, maakvar)
			n = n + m
		end
		res, num = t, n
	end
	local ref = X('~'..maakvar())
	ref.exp = res
	exp.ref = ref.v
	if isfn(exp) then
		al[moes(exp)] = {ref, num}
	end
	return res, num
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
