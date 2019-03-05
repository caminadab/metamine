require 'exp'

function isvar(name)
	if not isatoom(name) then
		return false
	end
	if tonumber(name) then
		return false
	elseif string.upper(name) == name then
		return false
	end
	return true
end

function var(exp,t)
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
	if not isfn(exp) then
		if not c(exp) then t[exp] = true end
	else
		for k,v in pairs(exp) do
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

function isatoom(exp)
	return type(exp) ~= 'table'
end

function isexp(exp)
	return type(exp) == 'table'
end

function substitueer(exp, van, naar)
	if isatoom(exp) then
		if exp == van then
			return naar
		else
			return exp
		end
	else
		local t = {}
		for k,v in pairs(exp) do
			t[k] = substitueer(v, van, naar)
		end
		local fn
		if t.type == 'eq' then
			fn = maakeq(t[1],t[2])
		else
			fn = maakfn(t)
		end
		return fn
	end
end

