require 'exp'
require 'symbool'

local altijdja = X('_fn', '12358', '⊤')
local calls = set('call', 'call1', 'call2', 'call3', 'call4')

function destart(exp)
	if fn(exp) == '..' then
		return arg0(exp)
	end
end

function devec(exp)
	if fn(exp) == '..' then
		if atoom(arg0(exp)) == '0' then
			return X('igen', arg1(exp))
		else
			return X('igeni', arg2(exp), arg1(exp))
		end
	end
end

local unop   = set("-","#","¬","Σ","|","⋀","⋁","√","|")
local postop = set("%","!",".","'")
local binop  = set("+","·","/","^","∨","∧","×","..","→","∘","_","⇒",">","≥","=","≠","≈","≤","<",":=","+=","|=","|:=", "∪","∩",":","∈","‖")
local op     = unie(binop, unie(postop, unop))

function stub2func(exp, maakindex)
	local naam = atoom(exp)
	local index = tostring(maakindex())
	if binop[naam] then
		local a0 = X('_arg0', index)
		local a1 = X('_arg1', index)
		return X('_fn', index, X(naam, a0, a1))
	elseif unop[naam] or postop[naam] then
		local a = X('_arg', index)
		return X('_fn', index, X(naam, a))
	else
		error('onbekende operator "'..naam..'"')
	end
end

-- atoom -> functie
function refunc(exp, maakindex)
	local klaar = {}
	local maakindex = maakindex or maakindices(444)

	for exp in boompairs(exp) do
		if op[atoom(exp)] then
			local nexp = stub2func(exp, maakindex)
			assign(exp, nexp)
		end
	end

	return exp
end

-- (+), id 

-- optimiseer compositie
local function compopt0(exp, maakindex)
	local a = arg0(exp)
	local b = arg1(exp)
	if fn(a) == '_fn' and fn(b) == '_fn' then
		local abody = arg1(a)
		local bbody = arg1(b)
		local aarg = atoom(arg0(a))
		local barg = atoom(arg0(b))
		local cindex = tostring(maakindex())
		local carg = X('_arg', cindex)
		local carg0 = X('_arg0', cindex)
		local carg1 = X('_arg1', cindex)
		local carg2 = X('_arg2', cindex)
		local carg3 = X('_arg3', cindex)
		
		local nbody = kloon(bbody)

		local aabody = kloon(abody)
		local aabody = substitueer(aabody, X('_arg', aarg), carg)
		local aabody = substitueer(aabody, X('_arg0', aarg), carg0)
		local aabody = substitueer(aabody, X('_arg1', aarg), carg1)
		local aabody = substitueer(aabody, X('_arg2', aarg), carg2)
		local aabody = substitueer(aabody, X('_arg3', aarg), carg3)

		local cbody = substitueer(nbody, X('_arg', barg), aabody)
		local c = X('_fn', cindex, cbody)
		--print(combineer(abody))
		--print(combineer(bbody))
		--print(combineer(c))

		return c

	-- (-) ∘ (-) = (x → -(-(x)))
	elseif isatoom(a) and isatoom(b) then
		error'OK'
		local index = tostring(maakindex())
		local anaam = atoom(a)
		local bnaam = atoom(b)

		local arg = X('_arg', index)
		local c
		if unop[anaam] then
			c = X(anaam, arg)
		elseif binop[anaam] then
			local argA = X('arg0', index)
			local argB = X('arg1', index)
			c = X(anaam, argA, argB)
		else
			c = X('call', anaam, arg)
		end
		local d
		if unop[bnaam] then
			d = X(bnaam, c)
		else
			d = X('call', bnaam, c)
		end

		return X('_fn', index, d)
	end
end

function compopt(exp, maakindex)
	for exp in boompairsdfs(exp) do
		if fn(exp) == '∘' then
			local nexp = compopt0(exp, maakindex)
			if nexp then
				assign(exp, nexp)
			end
		end
	end
	return exp
end

local function multiopt(exp, maakindex)
	for exp in boompairsbfs(exp) do
		-- som
		if fn(exp) == 'Σ' then
			local nexp = X('call3', 'reduceer', '0', arg(exp), '+')
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
		if fnaam(exp) == 'reduceer' and fnaam(arg2(exp)) == 'map' then
			-- reduceer(S,map(L,F),G), G=(X,Y → Z)
			-- > reduceer(S,L,H), H=(V,W → G(V, F(W)))
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

		-- filter/reduce
		if fnaam(exp) == 'reduceer' and fnaam(arg2(exp)) == 'filter' then
			--reduce(S,filter(L,F),G), G=(X,Y → Z)
			-- > reduceer(S,L,H), H=(V,W → kies(F(W),G(V,W),V))
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

		-- map/map
		if fnaam(exp) == 'map' and fnaam(arg1(exp)) == 'map' then
			-- map(map(A,B),C) → map(A, B ∘ C)
			local A = arg1(arg1(exp))
			local B = arg2(arg1(exp))
			local C = arg2(exp)
			local BC = X('∘', B, C)
			local nexp = X('call2', 'map', A, BC)
			assign(exp, nexp)
		end

		-- lus
		if fnaam(exp) == 'reduceer' then
			local gen = devec(arg2(exp))
			if gen then
				local nexp = X('lus', arg1(exp), gen, arg3(exp))
				assign(exp, nexp)
			end
		end
	end

	return exp
end

-- _f2(_fn(1 X) Y) X[_arg(1)=Y]
local function callopt(exp, maakindex)
	for exp in boompairs(exp) do
		if calls[fn(exp)] and arg0(exp) and fn(arg0(exp)) == '_fn' then
			local index = atoom(arg0(arg0(exp)))
			local lichaam = arg1(arg0(exp))

			local narg1 = arg1(exp)
			local narg2 = arg2(exp)
			local narg3 = arg3(exp)
			local narg4 = arg4(exp)

			local nexp = kloon(lichaam)
			local nexp = substitueer(nexp, X('_arg', index), narg1)
			local nexp = substitueer(nexp, X('_arg0', index), narg1)
			local nexp = substitueer(nexp, X('_arg1', index), narg2)
			local nexp = substitueer(nexp, X('_arg2', index), narg3)
			local nexp = substitueer(nexp, X('_arg3', index), narg4)

			assign(exp, nexp)
		end
	end

	return exp
end


-- lus: gen,map,col
function optimiseer(exp)
	local maakindex = maakindices(333)
	local exp = multiopt(exp, maakindex)
	local exp = refunc(exp, maakindex)
	local exp = compopt(exp, maakindex)
	local exp = callopt(exp, maakindex)

	return exp
end

				

