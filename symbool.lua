require 'exp'

local assoc = set{'+', '=', 'and', 'or', 'xor', 'nor', '·', '∘'}

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

function substitueer(exp, van, naar, klaar)
	local klaar = klaar or {}
	if klaar[exp] then return klaar[exp], 1 end
	if isatoom(exp) then
		if exp.v == van.v then
			klaar[exp] = naar
			return naar, 1
		else
			klaar[exp] = exp
			return exp, 0
		end
	else
		if isfn(van) then
			if moes(exp) == moes(van) then
				klaar[exp] = naar
				return naar, 1
			end
		end
		local t = {loc=exp.loc,o=exp.o,f=exp.f}
		local n = 0
		for k,v in subs(exp) do
			t[k],m = substitueer(v, van, naar, klaar)
			n = n + m
		end
		klaar[exp] = t
		return t, n
	end
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
