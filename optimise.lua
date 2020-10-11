require 'exp'
require 'symbol'
require 'constoptm'

local altijdja = X('_fn', '12358', '⊤')
local calls = set('call', 'call1', 'call2', 'call3', 'call4')

function destart(exp)
	if fn(exp) == '..' then
		return arg0(exp)
	end
end

function devec(exp, i)
	local i = i or 0
	local van = tonumber(atom(arg0(exp)))
	if fn(exp) == '×' then
		return nil --X(',', devec(arg0(exp)), devec(arg1(exp)))
	end
	if fn(exp) == '..' and van then
		if van == 0 and i == 0 then
			return X('igeni', '0', arg1(exp))
		elseif i == 0 then
			return X('igeni', X(tostring(van)), arg1(exp))
		elseif van == 0 then
			return X('igeni', X(tostring(i or 0)), arg1(exp))
		else
			return X('igeni', tostring(i + van), arg1(exp))
		end
	end
end

function defirst(exp, i)
	if fn(exp) == '..' then
		if i and i ~= 0 then
			return X('+', arg0(exp), tostring(i))
		else
			return arg0(exp)
		end
	end
end

local unop   = set("-","#","¬","Σ","|","⋀","⋁","√","|")
local postop = set("%","!",".","'",'²','³')
local binop  = set("+","·","/","^","∨","∧","×","..","→","∘","_",">","≥","=","≠","≈","≤","<",":=","+=","|=","|:=", "∪","∩",":","∈","‖")
local triop  = set('⇒')
local op     = unie(unie(binop, unie(postop, unop)), triop)

function stub2func(exp, maakindex)
	local name = atom(exp)
	local index = tostring(maakindex())
	if binop[name] then
		local a0 = X('_arg0', index)
		local a1 = X('_arg1', index)
		return X('_fn', index, X(name, a0, a1))
	elseif triop[name] then
		local a0 = X('_arg0', index)
		local a1 = X('_arg1', index)
		local a2 = X('_arg2', index)
		return X('_fn', index, X(name, a0, a1, a2))
	elseif unop[name] or postop[name] then
		local a = X('_arg', index)
		return X('_fn', index, X(name, a))
	else
		error('onbekende operator "'..name..'"')
	end
end

-- atom -> functie
function refunc(exp, maakindex)
	local maakindex = maakindex or maakindices(444)

	for exp in treepairs(exp) do
		if op[atom(exp)] then
			local nexp = stub2func(exp, maakindex)
			assign(exp, nexp)
		end
	end

	return exp
end

-- (+), id 

-- optimise compositie
local function compopt0(exp, maakindex)
	local a = arg0(exp)
	local b = arg1(exp)
	if fn(a) == '_fn' and fn(b) == '_fn' then
		local abody = arg1(a)
		local bbody = arg1(b)
		local aarg = atom(arg0(a))
		local barg = atom(arg0(b))
		local cindex = tostring(maakindex())
		local carg = X('_arg', cindex)
		local carg0 = X('_arg0', cindex)
		local carg1 = X('_arg1', cindex)
		local carg2 = X('_arg2', cindex)
		local carg3 = X('_arg3', cindex)
		
		local nbody = clone(bbody)

		local aabody = clone(abody)
		local aabody = substitute(aabody, X('_arg', aarg), carg)
		local aabody = substitute(aabody, X('_arg0', aarg), carg0)
		local aabody = substitute(aabody, X('_arg1', aarg), carg1)
		local aabody = substitute(aabody, X('_arg2', aarg), carg2)
		local aabody = substitute(aabody, X('_arg3', aarg), carg3)

		local cbody = substitute(nbody, X('_arg', barg), aabody)
		local c = X('_fn', cindex, cbody)
		--print(deparse(abody))
		--print(deparse(bbody))
		--print(deparse(c))

		return c

	end
end

function compopt(exp, maakindex)
	for exp in treepairsdfs(exp) do
		if fn(exp) == '∘' then
			local nexp = compopt0(exp, maakindex)
			if nexp then
				assign(exp, nexp)
			end
		end
	end
	return exp
end

local mappen = set('map') --, 'mapl')
-- reduceer(S,map(L,F),G), G=(X,Y → Z)

-- > reduceer(S,L,H), H=(V,W → G(V, F(W)))
local function mapreduceer(exp, maakindex)
	if fname(exp) == 'reduceer' and mappen[fname(arg2(exp))] then
		local S = arg1(exp)
		local L = arg1(arg2(exp))
		local F = arg2(arg2(exp))
		local G = arg3(exp)

		local I = tostring(maakindex())
		local V = X('_arg0', I)
		local W = X('_arg1', I)

		local hbody = X('call2', G, V, X('call', F, W))
		local H = X('_fn', I, hbody)
		local nexp = X('call3', 'reduceer', S, L, H)
		assign(exp, nexp)
	end
-- reduceerbreak(S,map(L,F),G,B), G=(X,Y → Z)
-- > reduceerbreak(S,L,H,B), H=(V,W → G(V, F(W)))
	if fname(exp) == 'reduceerbreak' and mappen[fname(arg2(exp))] then
		local S = arg1(exp)
		local L = arg1(arg2(exp))
		local F = arg2(arg2(exp))
		local G = arg3(exp)
		local B = arg3(exp)

		local I = tostring(maakindex())
		local V = X('_arg0', I)
		local W = X('_arg1', I)

		local hbody = X('call2', G, V, X('call', F, W))
		local H = X('_fn', I, hbody)
		local nexp = X('call4', 'reduceerbreak', S, L, H, B)
		assign(exp, nexp)
	end
	return exp
end


-- reduceer(S,lmap(L,F),G), G=(X,Y → Z)
-- > reduceer(S,L,H), H=(V,W → G(V, F[W]))
local function lmapreduceer(exp, maakindex)
	if fname(exp) == 'reduceer' and fname(arg2(exp)) == 'lmap' then
		local S = arg1(exp)
		local L = arg1(arg2(exp))
		local F = arg2(arg2(exp))
		local G = arg3(exp)

		local I = tostring(maakindex())
		local V = X('_arg0', I)
		local W = X('_arg1', I)

		local hbody = X('call2', G, V, X('index', F, W))
		local H = X('_fn', I, hbody)
		local nexp = X('call3', 'reduceer', S, L, H)
		assign(exp, nexp)
	end
	return exp
end

-- vouw(map(L,F),G), G=(X,Y → Z)
-- > vouw(L,H), H=(V,W → G(V, F(W)))
local function mapvouw(exp, maakindex)
	if fname(exp) == 'vouw' and fname(arg1(exp)) == 'map' then
		local L = arg1(arg1(exp))
		local F = arg2(arg1(exp))
		local G = arg2(exp)

		local I = tostring(maakindex())
		local V = X('_arg0', I)
		local W = X('_arg1', I)

		local hbody = X('call2', G, V, X('call', F, W))
		local H = X('_fn', I, hbody)
		local nexp = X('call2', 'vouw', L, H)
		assign(exp, nexp)
		--error(deparse(nexp))
	end
	return exp
end

local function filtervouw(exp, maakindex)
	if fname(exp) == 'vouw' and fname(arg1(exp)) == 'filter' then
		--vouw(filter(L,F),G), G=(X,Y → Z)
		-- > vouw(L,H), H=(V,W → (⇒)(F(W),G(V,W),V))
		local L = arg1(arg1(exp))
		local F = arg2(arg1(exp))
		local G = arg2(exp)

		local I = tostring(maakindex())
		local V = X('_arg0', I)
		local W = X('_arg1', I)

		local hbody = X('⇒', X('call', F, W), X('call2',G,V,W), V)
		local H = X('_fn', I, hbody)
		local nexp = X('call2', 'vouw', L, H)
		
		assign(exp, nexp)
	end
	return exp
end

local function filterreduceer(exp, maakindex)
	if fname(exp) == 'reduceer' and fname(arg2(exp)) == 'filter' then
		--reduceer(S, filter(L,F),G), G=(X,Y → Z)
		-- > reduceer(S,L,H), H=(V,W → (⇒)(F(W),G(V,W),V))
		local S = arg1(exp)
		local L = arg1(arg2(exp))
		local F = arg2(arg2(exp))
		local G = arg3(exp)

		local I = tostring(maakindex())
		local V = X('_arg0', I)
		local W = X('_arg1', I)

		local hbody = X('⇒', X('call', F, W), X('call2',G,V,W), V)
		local H = X('_fn', I, hbody)
		local nexp = X('call3', 'reduceer', S, L, H)
		
		assign(exp, nexp)
	end
	return exp
end


local function multiopt(exp, maakindex)
	local klaar = {}
	for exp in treepairsdfs(exp) do

		-- som
		if fn(exp) == 'Σ' then
			local nexp = X('call3', 'reduceer', '0', arg(exp), '+')
			assign(exp, nexp)
		end

		-- en
		if fn(exp) == '⋀' then
			local nexp = X('call4', 'reduceer', '⊤', arg(exp), '∧')
			assign(exp, nexp)
		end

		-- of
		if fn(exp) == '⋁' then
			local nexp = X('call3', 'reduceer', '⊥', arg(exp), '∨')
			assign(exp, nexp)
		end

		-- lengte
		if false and fn(exp) == '#' then
			local index = tostring(maakindex())
			local plus = X('_fn', index, X('+', X('_arg0', index), '1'))
			local nexp = X('call3', 'reduceer', '0', arg(exp), plus)
			assign(exp, nexp)
		end

		-- map/reduce
		exp = mapreduceer(exp, maakindex)
		exp = lmapreduceer(exp, maakindex)
		exp = filterreduceer(exp, maakindex)

		exp = mapvouw(exp, maakindex)
		exp = filtervouw(exp, maakindex)

		exp = mapreduceer(exp, maakindex)

		-- map/map
		if fname(exp) == 'map' and fname(arg1(exp)) == 'map' then
			-- map(map(A,B),C) → map(A, B ∘ C)
			local A = arg1(arg1(exp))
			local B = arg2(arg1(exp))
			local C = arg2(exp)
			local BC = X('∘', B, C)
			local nexp = X('call2', 'map', A, BC)
			assign(exp, nexp)
		end

		-- lus
		if fname(exp) == 'vouw' then
			local gen = devec(arg1(exp), 1)
			local first = defirst(arg1(exp))
			if gen then
				local nexp = X('lus', first, gen, arg2(exp))
				assign(exp, nexp)
			end
		end

		-- lus
		if fname(exp) == 'reduceer' then
			local gen = devec(arg2(exp))
			if gen then
				local nexp = X('lus', arg1(exp), gen, arg3(exp))
				assign(exp, nexp)
			end
		end

		-- lus
		if fname(exp) == 'reduceerbreak' then
			--error(unlisp(devec(arg2(exp))))
			local gen = devec(arg2(exp))
			local cond = devec(arg3(exp))
			if gen then
				local nexp = X('lusbreak', arg1(exp), gen, arg3(exp), cond)
				assign(exp, nexp)
			end
		end

		-- vlus
		if false and fname(exp) == 'map' then
			local gen = devec(arg1(exp))
			local func = arg2(exp)
			if gen then
				local idx = tostring(maakindex())
				local lijst = X('[]', '0')
				lijst[1] = nil
				local nexp = X('lus', lijst, gen, X('_fn', idx, X('||=', X('_arg0',idx), X('call', func, X('_arg1',idx)))))
				assign(exp, nexp)
			end
		end

		-- vlus
		if false and fname(exp) == 'filter' then
			local gen = devec(arg1(exp))
			local func = arg2(exp)
			local body = arg1(func)
			if gen then
				local idx = tostring(maakindex())
				local lijst = X('[]', '0')
				lijst[1] = nil
				local kies = X('⇒', body, X('||=', X('_arg0',idx), X('_arg1',idx)))
				local nexp = X('lus', lijst, gen, X('_fn', idx, kies))
				assign(exp, nexp)
			end
		end

	end

	return exp
end

local function argopt(exp, maakindex)
	for exp in treepairs(exp) do
		if fn(exp) == 'call' and obj(arg1(exp)) == ',' then
			local nargs = #arg1(exp)
			if 2 <= nargs and nargs <= 4 then
				exp.f = X('call'..tostring(nargs))
				local o = arg1(exp)
				exp.a = X(',', arg0(exp), o[1], o[2], o[3], o[4])
			end
		end
	end
	return exp
end

-- _f2(_fn(1 X) Y) X[_arg(1)=Y]
local function callopt(exp, maakindex)
	for exp in treepairs(exp) do
		if calls[fn(exp)] and arg0(exp) and fn(arg0(exp)) == '_fn' then
			local index = atom(arg0(arg0(exp)))
			local lichaam = arg1(arg0(exp))

			local narg1 = arg1(exp)
			local narg2 = arg2(exp)
			local narg3 = arg3(exp)
			local narg4 = arg4(exp)

			local nexp = clone(lichaam)
			local nexp = substitute(nexp, X('_arg', index), narg1)
			local nexp = substitute(nexp, X('_arg0', index), narg1)
			local nexp = substitute(nexp, X('_arg1', index), narg2)
			local nexp = substitute(nexp, X('_arg2', index), narg3)
			local nexp = substitute(nexp, X('_arg3', index), narg4)

			assign(exp, nexp)
		end
	end

	return exp
end


-- lus: gen,map,col
function optimise(exp)
	local maakindex = maakindices(333)
	local exp = multiopt(exp, maakindex)
	local exp = refunc(exp, maakindex)
	local exp = compopt(exp, maakindex)
	local exp = argopt(exp, maakindex)
	local exp = callopt(exp, maakindex)
	--local exp = constoptm(exp)

	return exp
end

				

