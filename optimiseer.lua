require 'util'
require 'bieb'
local bieb = bieb()
local makkelijk = set('+', '-', '·', '/', '%', '#', '_', '^',  '√', '∧', '∨', 'Σ', '>', '<', '≥', '≤', '=', '≠', '⇒', '⊤', '⊥', '_l', '_t', '_t')
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

local function fnaam(exp)
	return isfn(exp) and fn(exp):sub(1,1) == '_' and atoom(arg0(exp))
end

local function sourcelen(exp)
	if fn(exp) == '..' then
		return X('+', arg1(exp), X('-', arg0(exp)))
	end
	if fnaam(exp) == 'map' then
		return sourcelen(arg1(exp)[1])
	end
	if fnaam(exp) == 'zip' then
		return sourcelen(arg1(exp)[1])
	end
	if isobj(exp) then
		return X(tostring(#exp))
	end
	if fn(exp) == '×' then
		return X('·', sourcelen(arg0(exp)), sourcelen(arg1(exp)))
	end
	return X('#', exp)
end

-- genereer un source
local function sourcegen(exp)
	if fn(exp) == '..' then
		return X('_f', 'fn.plus', arg0(exp))
	end
	if fnaam(exp) == 'map' then
		local a = arg1(exp)[1]
		local f = arg1(exp)[2]
		return X('∘', sourcegen(a), f)
	end
	if fnaam(exp) == 'zip' then
		local a, b = arg1(exp)[1], arg1(exp)[2]
		local arg = X(',', sourcegen(a), sourcegen(b))
		return X('_f', 'fn.merge', arg)
	end
	if isobj(exp) then
		-- i → y[i]
		return X('_fn', '777', X('_l', exp, X('_arg', '777')))
	end
	if fn(exp) == '×' then
		--local a = 
		local len = sourcelen(arg0(exp))
		local mod = X('_f', 'mod', X(',', X('_arg', '888'), len))
		local modplus = X('+', mod, sourcegen(arg0(exp)))
		local div = X('_f', 'afrond.onder', X('/', X('_arg', '888'), sourcelen(arg0(exp))))
		return X('_fn', '888', X(',', div, mod))
	end
	--error(unlisp(exp))
	return X'fn.id'
end

function optimiseer(exp)
	--do return exp end
	local num = 0
	local function rec(exp) 

		if false and  fn(exp) ==  '..' then
			local len = sourcelen(exp)
			local gen = sourcegen(exp)
			local nexp = X('_f', 'lvoor', X(',', len, '0', gen))

			--print('cool', combineer(nexp))
			assign(exp, nexp)
			num = num + 1
		end

		if false and fnaam(exp) ==  'map' then
			local lijst,map = arg1(exp)[1], arg1(exp)[2]
			local len = sourcelen(lijst)
			local gen = sourcegen(lijst)
			local nexp = X('_f', 'lvoor', X(',', len, X('∘', gen, map)))

			print('cool', combineer(map))
			assign(exp, nexp)
			num = num + 1
		end

		if fnaam(exp) == 'vouw' then
			local lijst,vouw = arg1(exp)[1], arg1(exp)[2]
			local len = sourcelen(lijst)
			local gen = sourcegen(lijst)

			local max = X('+', len, '-1')
			local start = X('_', gen, '0')
			local map = X('∘', X('_f', 'fn.plus', '1'), gen)
			local vouw = vouw

			local nexp = X('_f', 'voor', X(',', max, start, map, vouw))
			print('cool')
			print('max', combineer(max))
			print('start', combineer(start))
			print('map', combineer(map))
			print('vouw', combineer(vouw))

			assign(exp, nexp)
			num = num + 1
		end

		if fn(exp) == 'Σ' then
			local len = sourcelen(arg(exp))
			local gen = sourcegen(arg(exp))

			local nexp = X('_f', 'voor', X(',', len, '0', gen, '+'))
			--print('cool', combineer(nexp))

			assign(exp, nexp)
			num = num + 1
		end

		for k, sub in subs(exp) do
			rec(sub)
		end

	end
	rec(exp)
	print(num..' optimisaties uitgevoerd')
	return exp
end

function optimiseer3(exp)
	local num = 0
	local function rec(exp) 
		for k, sub in subs(exp) do
			rec(sub)
		end

		-- collector
		if fn(exp) == 'Σ' then
			--error(unlisp(arg(exp)))
			local len = sourcelen(arg(exp))
			--local gen = gen(arg(exp))
			local nexp = X('_', 'voor', X(',', len, '0', '+'))
			assign(exp, nexp)
			num = num + 1
		end

		-- x map y map z → x map (y ∘ z)
		if false and fnaam(exp) == 'map' then
			local lijst = arg1(exp)[1]
			local mapfunctie1 = arg1(exp)[2]
			if fn(lijst) == '_f' and atoom(arg0(lijst)) == 'map' then
				local lijst2 = arg1(lijst)[1]
				local mapfunctie2 = arg1(lijst)[2]
				--error (unlisp(mapfunctie2))

				local mapfunctie = X('∘', mapfunctie1, mapfunctie2)
				local nexp = X('_f', 'map', X(',', lijst2, mapfunctie))
				assign(exp, nexp)
				num = num + 1
			end
		end

		local function fnaam(exp)
			return (fn(exp) == '_f' or fn(exp) == '_') and atoom(arg0(exp))
		end

		-- x map y vouw z
		if fnaam(exp) == 'vouw' then
			local lijst = arg1(exp)[1]
			local vouwfunctie = arg1(exp)[2]

			if fnaam(lijst) == 'map' then
				--error'OK'
				local lijst2 = arg1(lijst)[1]
				local mapfunctie = arg1(lijst)[2]
				--error('vouw ' .. unlisp(vouwfunctie))

				local a = X('_l', X('_arg', '999'), '0')
				local b = X('_l', X('_arg', '999'), '1')
				local yayb = X(',', X('_', mapfunctie, a), X('_', mapfunctie, b))
				local f = X('_fn', '999', X('_', vouwfunctie, yayb))
				local nexp = X('_', 'vouw', X(',', lijst2, f))
				assign(exp, nexp)
				num = num + 1
			end
		end
		return exp
	end
	local res =  rec(exp)
	print(num..' optimisaties toegepast')
	return res
end

-- constanten vouwen
function optimiseer2(exp)

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
			else
				return nil, bieb[atoom(exp)]
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
