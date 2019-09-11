require 'exp'

local predef = {
	sin = "asin",
	cos = "acos",
	tan = "atan",
	asin = "sin",
	acos = "cos",
	atan = "tan",
	wortel = X("^", "_", "2"),
	tekst = "getal",
	getal = "tekst",
}

inverteer_def = predef

-- isoleer (a+b=c, a) ↦ c-b
function isoleer(eq,naam)
	assert(isatoom(naam), 'naam is geen atoom')
	if fn(eq) ~= '=' then return false end
	local flip = false
	while true do
		local eq0
		local L,R
		if not flip then
			L,R = eq.a[1],eq.a[2]
			flip = true
		else
			R,L = eq.a[1],eq.a[2]
			flip = false
		end
		if naam.v == L.v then return R end
		if naam.v == R.v then return L end

		if isfn(L) and not isobj(L.a) then
			local fn,f,a,x = L.f, L.f.v, L.a[1], R
			local out
			local n = 0
			if bevat(a,naam) then out = 0; n = n + 1 end
			if bevat(x,naam) then out = 1; n = n + 1 end
			if bevat(fn,naam) then out = 2; n = n + 1 end
			if n ~= 1 then
				return false -- onoplosbaar
			end

			if f == '-' then
				-- x = - a
				if out == 0 then eq0 = X(':=', a, X('-', x)) end -- a = - x
				--if out == 1 then eq0 = {'=', x, {'-', a}} end -- x = - a
			elseif predef[f] then
				if out == 0 then eq0 = X(':=', a, X(predef[f], x)) end
			elseif f == '%' then
				-- x = a%
				if out == 0 then eq0 = X(':=', a, X('*', x, 100)) end -- a = x * 100
				if out == 1 then eq0 = X(':=', x, X('/', a, 100)) end -- x = a / 100  (gewoon procent)
			else
				-- x = f(a)
				--if out == 0 then eq0 = {'=', a, {{'^', f, '-1'}, x}} end -- a = (f^-1) x
				if out == 0 then eq0 = X(':=', a, X(X('inverteer', f), x)) end -- a = (f^-1) x
				--if out == 2 then eq0 = {'=', f, {'→', a, x}} end -- f = a → x
			end
		end
		if fn(L) == '{}' then
			-- a = [x,b]
			for i,el in ipairs(L) do
				if bevat(el,name) then
					eq0 = X(':=', el, X(R, tostring(i-1))) -- functioneel
					--eq0 = X(':=', el, X(tostring(i-1))) -- definieerened
					break
				end
			end
		-- lijst
		elseif fn(L) and (fn(L) == '[]' or fn(L) == ',') then
			-- a = [x,b]
			for i,el in ipairs(l) do
				if bevat(el,name) then
					eq0 = X(':=', el, X(R, tostring(i-1)))
					break
				end
			end
		elseif isfn(L) and isobj(L.a) then
			local x,f,a,b = R, fn(L), L.a[1],L.a[2]
			local out
			local n = 0
			if bevat(a,naam) then out = 0; n = n + 1 end
			if bevat(b,naam) then out = 1; n = n + 1 end
			if bevat(x,naam) then out = 2; n = n + 1 end
			if n ~= 1 then
				--log('FOUT',unlisp(eq),name)
				return false -- onoplosbaar
			end

			if f == '+' then
				-- x = a + b
				if out == 0 then eq0 = X(':=', a, X('-', x, b)) end -- a = x - b
				if out == 1 then eq0 = X(':=', b, X('-', x, a)) end -- b = x - a
				--if out == 2 then eq0 = {'=', x, {'+', a, b)) end -- x = a + b
			elseif f == '-' then
				-- x = a - b
				if out == 0 then eq0 = X(':=', a, X('+', x, b)) end -- a = x - b
				if out == 1 then eq0 = X(':=', b, X('-', x, a)) end -- b = x + a
				--if out == 2 then eq0 = {'=', x, {'-', a, b}} end -- x = a - b
			elseif f == '·' then
				-- x = a * b
				if out == 0 then eq0 = X(':=', a, X('/', x, b)) end -- a = x / b
				if out == 1 then eq0 = X(':=', b, X('/', x, a)) end -- b = x / a
				--if out == 2 then eq0 = {'=', x, {'*', a, b}} end -- x = a * b
			elseif f == '/' then
				-- x = a / b
				if out == 0 then eq0 = X(':=', a, X('·', x, b)) end -- a = x * b
				if out == 1 then eq0 = X(':=', b, X('/', a, x)) end -- b = a / x
				--if out == 2 then eq0 = {'=', x, {'/', a, b}} end -- x = a / b
			elseif f == '^' then
				-- x = a ^ b
				if out == 0 then eq0 = X(':=', a, X('^', x, X('/', '1', b))) end -- a = x ^ (1 / a)
				if out == 1 then eq0 = X(':=', b, X('log', a, x)) end -- b = a _ x
				--if out == 2 then eq0 = {'=', x, {'^', a, b}} end -- x = a ^ b
			elseif f == '|' then
				-- x = a | b
				if out == 0 then eq0 = X(':=', a, X('⇒', X('!', b), x)) end -- a = (¬b ⇒ x)
				if out == 1 then eq0 = X(':=', b, X('⇒', X('!', a), x)) end -- b = (¬a ⇒ x)
				--if out == 2 then eq0 = {'=', x, {'^', a, b)} end -- x = a ^ b
			elseif f == '::' then
				-- x = a :: b
				-- a = x₀
				if out == 0 then eq0 = X(':=', a, X(x, '0')) end
				 -- b = x vanaf 1
				if out == 1 then eq0 = X(':=', b, X('vanaf', x, '1')) end
				 -- x = [a] ‖ b
				if out == 2 then eq0 = X(':=', x, X('‖', X('[]', a), b)) end
			elseif f == '‖' then
				-- x = a ‖ b
				-- a = x (0..(#x-#b))
				if out == 0 then eq0 = X(':=', a, X('deel', x, X('[]', '0', X('-', X('#', x), X('#',b))))) end
				 -- b = x (#a..#x)
				if out == 1 then eq0 = X(':=', b, X('deel', x, X('[]', X('#', a), X('#', x)))) end
				--??? if out == 2 then eq0 = {'=', x, {'‖', a, b}} end -- x = a ‖ b
				--VROEGER if out == 0 then eq0 = X(':=', a, X(x, X('..', '0', X('-', X('#', x}, X('#',b}}}}} end
				--VROEGER if out == 1 then eq0 = X(':=', b, X(x, X('..', X('#', a}, X('#', x}}}} end -- b = x (#a..#x)
			else
				if print_niet_isoleerbaar then
					log('weet niet hoe te isoleren '..f)
				end
				return false -- kan operator niet oplossen
			end
		end

		if not eq0 and not flip then break end
		if eq0 then
			if verboos or true then print(exp2string(eq) .. ' → '..exp2string(eq0)) end 
			eq = eq0
			flip = false
		end
	end
end

if false and test then
	verboos = true
	require 'ontleed'
	assert(isoleer(ontleed('a = b')[1], X'b').v == 'a')
	assert(isoleer(ontleed('a = b')[1], X'a').v == 'b')
	verboos = false
end

local L,U = lisp,unlisp

--[[
tests = {
	{'(= a b)', 'b', '(:= b a)'},
	{'(= a b)', 'a', '(:= a b)'},

	{'(= 7 (+ (+ a 1) 2))', 'a', '(:= a (- (- 7 2) 1))'},
	{'(= (+ a b) c)', 'a', '(:= a (- c b))'},
	{'(= c (+ a b))', 'a', '(:= a (- c b))'},
	{'(= 6 (* a 3))', 'a', '(:= a (/ 6 3))'},
	{'(= b (* (/ a 2) c))', 'a', '(:= a (* (/ b c) 2))'},
	{'(= c (+ (* a 2) (* b 2)) c)', 'a', '(:= a (/ (- c (* b 2)) 2))'}, -- c = a * 2 + b * 2. a?

	{'(= a (- b))', 'b', '(:= b (- a))'},
}

for i,test in ipairs(tests) do
	local eq = L(test[1])
	local name = L(test[2])
	local r = isoleer(eq, name)
	assert(U(r) == test[3], 'test #'..i..': '..test[1]..' voor '..name .. ' was '..U(r)..' maar hoort '..test[3])
end
]]
