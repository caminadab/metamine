require 'exp'
require 'func'
require 'set'

local postop = set("%","!",".","'")
local binop  = set("+","·","/","^","∨","∧","×","..","→","∘","_","⇒",">","≥","=","≠","≈","≤","<",":=","+=","|=","|:=", "∪","∩",":","∈","‖")
local unop   = set("-","#","¬","Σ","|","⋀","⋁","√","|")

local function combineerR(exp, t, kind)
	if not exp then
		t[#t+1] = '?'
	elseif isatoom(exp) and postop[exp.v] or binop[exp.v] or unop[exp.v] then
		t[#t+1] = '('
		t[#t+1] = exp.v
		t[#t+1] = ')'
	elseif isatoom(exp) then
		t[#t+1] = exp.v
	elseif obj(exp) == '"' then
		local const = true
		for i,sub in ipairs(exp) do
			if not tonumber(atoom(sub)) then
				const = false
			end
		end
		if const then
			local r = {}
			for i,sub in ipairs(exp) do
				r[#r+1] = tonumber(sub.v)
			end
			local tekst = string.char(table.unpack(r))
			t[#t+1] = string.format('%q', tekst):gsub('\n', 'n')

		else

			t[#t+1] = "unicode ["
			for i,v in ipairs(exp) do
				if i ~= 1 then
					t[#t+1] = ', '
				end
				combineerR(v, t, true)
			end
			t[#t+1] = "]"
		end

	elseif isobj(exp) then
		local di = obj(exp)
		if di == ',' then
			di = '()'
		end
		t[#t+1] = di:sub(1,1)
		for i,v in ipairs(exp) do
			if i ~= 1 then
				t[#t+1] = ', '
			end
			if i > 20 then
				t[#t+1] = '...'
				break
			end
			combineerR(v, t, true)
		end
		t[#t+1] = di:sub(2,2)

	-- explijst
	elseif fn(exp) == '⋀' and isobj(exp.a) then
		for i,sub in ipairs(exp.a) do
			combineerR(sub, t, false)
			t[#t+1] = '\n'
		end

	elseif isfn(exp) then
		if not exp.a then return '?' end
		local op = fn(exp)
		if op == '_' or op == '_l' and isobj(exp.a) then

			if isfn(exp.a[1]) then
				t[#t+1] = '('
			end
			combineerR(exp.a[1], t, true)
			if isfn(exp.a[1]) then
				t[#t+1] = ')'
			end

			t[#t+1] = ' '
			if not isobj(exp.a[2]) then
				t[#t+1] = '('
			end
			combineerR(exp.a[2], t, false)
			if not isobj(exp.a[2]) then
				t[#t+1] = ')'
			end

		-- a + b 
		elseif binop[op] and isobj(exp.a) then
			if kind then t[#t+1] = '(' end
			combineerR(exp.a[1], t, true)
			t[#t+1] = ' '
			t[#t+1] = op
			t[#t+1] = ' '
			combineerR(exp.a[2], t, true)
			if kind then t[#t+1] = ')' end

		elseif unop[op] then
			t[#t+1] = op
			t[#t+1] = ' '
			combineerR(exp.a, t, true)
		elseif postop[op] then
			combineerR(exp.a, t, true)
			t[#t+1] = op
		else
			t[#t+1] = '('
			t[#t+1] = op
			t[#t+1] = ')'
			if exp.a and not isobj(exp.a) then
				t[#t+1] = '('
			end
			combineerR(exp.a, t, false)
			if not isobj(exp.a) then
				t[#t+1] = ')'
			end
		end

	else
		--error('ongeldige exp '..e2s(exp))
		t[#t+1] = '?'
	end
end

function combineer(exp)
	local t = {}
	combineerR(exp, t, false)
	return table.concat(t)
end

-- combineer maar 1 level
function combineersimpel(exp)
	if isatoom(exp) then
		return combineer(exp)
	else
		local nep = {}
		nep.f = exp.f
		nep.o = exp.o
		for k,sub in subs(exp) do
			nep[k] = (isatoom(sub) and sub) or (sub.ref and X(sub.ref)) or X'...'
		end
		nep.exp = nil
		return combineer(nep)
	end
end

C = combineer
