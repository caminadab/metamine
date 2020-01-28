require 'util'
require 'bieb'
local bieb = bieb()
local makkelijk = set('+', '-', '·', '/', '%', '#', '_', '^',  '√', '∧', '∨')
local dynamisch = set('looptijd', 'nu', 'tcp.lees', 'tcp.schrijf', '_arg', 'schrijf', 'vierkant', 'cirkel', 'label', 'rechthoek', 'lijn', '_var', '_prevvar', 'toets.neer', 'muis.klik', 'muis.klik.begin', 'muis.klik.eind', 'toets.neer.begin', 'toets.neer.eind')

local function w2exp(w)
	local uit
	if w == true then
		uit = X'⊤'
	elseif w == false then
		uit = X'⊥'
	elseif w == nil then
		uit = X'niets'
	elseif type(w) == 'function' then
		uit = X'functie'
	elseif tonumber(w) then
		uit = X(tostring(w))
	elseif type(w) == 'table' then
		if w.isset then
			uit = X('{}', table.unpack(map(w, w2exp)))
		else
			uit = {}
			uit.o = X'[]'
			for i,v in ipairs(w) do
				uit[i] = w2exp(v)
			end
		end
	else
		uit = X(tostring(w))
	end
	uit.w = w
	return uit
end


-- constanten vouwen
function optimiseer(exp)

	-- literals
	if isatoom(exp) then
		if tonumber(atoom(exp)) then
			return exp, tonumber(atoom(exp))
		end
		if atoom(exp) == "⊤" then return exp, true end
		if atoom(exp) == "⊥" then return exp, false end
		if bieb[atoom(exp)] and not dynamisch[atoom(exp)] then return exp, bieb[atoom(exp)] end
		return exp, nil
	end

	-- objects
	if isobj(exp) then
		local nexp = {o=exp.o}
		local val = {}
		local isconstant = true
		for k, sub in subs(exp) do
			local sub, wsub = optimiseer(sub)
			nexp[k] = sub
			if wsub then
				val[k] = wsub
			else
				isconstant = false
			end
		end
		if isconstant then
			return nexp, val
		else
			return nexp, nil
		end
	end

	-- operators
	if isfn(exp) then
		local narg,warg = optimiseer(arg(exp))

		local nexp, wexp
		if makkelijk[fn(exp)] and warg then
			wexp = bieb[fn(exp)](warg)
			nexp = w2exp(wexp)
		else
			nexp = {f=exp.f, a=narg} --X(fn(exp), narg)
		end
		return nexp, wexp
	end

	assert(false)
end
