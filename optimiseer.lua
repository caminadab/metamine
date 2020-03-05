require 'util'
require 'bieb'
local bieb = bieb()
local makkelijk = set('+', '-', '·', '/', '%', '#', '_', '^',  '√', '∧', '∨', 'Σ', '>', '<', '≥', '≤', '=', '≠', '⇒', '⊤', '⊥', '_l', '_f', '_t')
local dynamisch = set('looptijd', 'nu', 'starttijd', 'start', '∘',
	'tcp.lees', 'tcp.schrijf', 'tcp.accepteer', 'tcp.bind',
	'pad.begin', 'pad.eind', 'pad.rect', 'pad.vul', 'pad.verf',
	'canvas.context', 'html',
	'_arg', 'schrijf', 'vierkant', 'cirkel', 'label', 'rechthoek', 'lijn', '_V', '_var', 'toets.neer', 'muis.klik', 'muis.klik.begin', 'muis.klik.eind', 'toets.neer.begin', 'toets.neer.eind', 'misschien', 'willekeurig', 'constant', 'id', 'merge', 'kruid')

local function w2exp(w)
	local uit
	if w == true then
		uit = X'⊤'
	elseif w == false then
		uit = X'⊥'
	elseif w == nil then
		uit = X'niets'
	elseif type(w) == 'function' then
		-- functies kunnen we (nog) niet tot waarde maken
		assert(false)
	elseif w == 1/0 then
		uit = X('/', '1', '0')
	elseif tonumber(w) then
		uit = X(tostring(w))
	elseif type(w) == 'string' then
		error'ok'
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
		if bieb[atoom(exp)] and not dynamisch[atoom(exp)] then
			if type(bieb[atoom(exp)]) ~= 'function' then
				return exp, bieb[atoom(exp)]
			end
		end
		return exp, nil
	end

	-- string
	if obj(exp) == '"' then
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
		assign(exp, nexp)
		nexp = exp
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
			if nexp == nil then
				wexp = nil
			end
		else
			if fn(exp) == '_fn' then
				wexp = nil
			end
			nexp = {f=exp.f, a=narg} --X(fn(exp), narg)
		end
		return nexp, wexp
	end

	assert(false)
end
