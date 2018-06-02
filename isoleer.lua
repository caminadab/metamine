require 'lisp'

function contains(exp, name)
	if atom(exp) then
		return exp == name
	else
		for i,v in ipairs(exp) do
			if contains(v,name) then return true end
		end
		return false
	end
end

-- rewrite (a + b = c, a) -> c - b
function isoleer(eq,name)
	local flip = false
	while true do
		local eq0
		local l,r
		if not flip then
			l,r = eq[2],eq[3]
			flip = true
		else
			r,l = eq[2],eq[3]
			flip = false
		end
		if name == l then return r end
		if name == r then return l end

		if exp(l) and #l == 2 then
			local f,a,x = l[1],l[2],r
			local out
			local n = 0
			if contains(a,name) then out = 0; n = n + 1 end
			if contains(x,name) then out = 1; n = n + 1 end
			if n ~= 1 then
				return false -- onoplosbaar
			end

			if f == '-' then
				-- x = - a
				if out == 0 then eq0 = {'=', a, {'-', x}} end -- a = - x
				--if out == 1 then eq0 = {'=', x, {'-', a}} end -- x = - a
			end
			if f == 'tekst' then
				-- x = tekst a
				if out == 0 then eq0 = {'=', a, {'getal', x}} end -- a = getal x
			end
			if f == 'getal' then
				-- x = tekst a
				if out == 0 then eq0 = {'=', a, {'tekst', x}} end -- a = tekst x
			end
		end
		if exp(l) and l[1] == '[]' then
			-- a = [x,b]
			for i,el in ipairs(l) do
				if contains(el,name) then
					eq0 = {'=', el, {r, i-1-1}}
					break
				end
			end
		end
		if exp(l) and #l == 3 then
			local x,f,a,b = r,l[1],l[2],l[3]
			local out
			local n = 0
			if contains(a,name) then out = 0; n = n + 1 end
			if contains(b,name) then out = 1; n = n + 1 end
			if contains(x,name) then out = 2; n = n + 1 end
			if n ~= 1 then
				log('FOUT',unlisp(eq),name)
				return false -- onoplosbaar
			end

			if f == '+' then
				-- x = a + b
				if out == 0 then eq0 = {'=', a, {'-', x, b}} end -- a = x - b
				if out == 1 then eq0 = {'=', b, {'-', x, a}} end -- b = x - a
				--if out == 2 then eq0 = {'=', x, {'+', a, b}} end -- x = a + b
			elseif f == '-' then
				-- x = a - b
				if out == 0 then eq0 = {'=', a, {'-', x, b}} end -- a = x - b
				if out == 1 then eq0 = {'=', b, {'-', x, a}} end -- b = x + a
				--if out == 2 then eq0 = {'=', x, {'-', a, b}} end -- x = a - b
			elseif f == '*' then
				-- x = a * b
				if out == 0 then eq0 = {'=', a, {'/', x, b}} end -- a = x / b
				if out == 1 then eq0 = {'=', b, {'/', x, a}} end -- b = x / a
				--if out == 2 then eq0 = {'=', x, {'*', a, b}} end -- x = a * b
			elseif f == '/' then
				-- x = a / b
				if out == 0 then eq0 = {'=', a, {'*', x, b}} end -- a = x * b
				if out == 1 then eq0 = {'=', b, {'/', a, x}} end -- b = a / x
				--if out == 2 then eq0 = {'=', x, {'/', a, b}} end -- x = a / b
			elseif f == '^' then
				-- x = a ^ b
				if out == 0 then eq0 = {'=', a, {'^', x, {'/', 1, b}}} end -- a = x ^ (1 / a)
				if out == 1 then eq0 = {'=', b, {'_', a, x}} end -- b = a _ x
				--if out == 2 then eq0 = {'=', x, {'^', a, b}} end -- x = a ^ b
			elseif f == '||' then
				-- x = a || b
				-- a = x (0..(#x-#b))
				if out == 0 then eq0 = {'=', a, {x, {'..', 0, {'-', {'#', x}, {'#',b}}}}} end
				if out == 1 then eq0 = {'=', b, {x, {'..', {'#', a}, {'#', x}}}} end -- b = x (#a..#x)
				--if out == 2 then eq0 = {'=', x, {'||', a, b}} end -- x = a || b
			else
				log('weet niet hoe te isoleren '..f)
				return false -- kan operator niet oplossen
			end
		end

		if not eq0 and not flip then break end
		if eq0 then
			--log(unlisp(eq) .. ' -> '..unlisp(eq0))
			eq = eq0
			flip = false
		end
	end
end

local L,U = lisp,unlisp

tests = {
	{'(= a b)', 'b', 'a'},
	{'(= a b)', 'a', 'b'},

	{'(= 7 (+ (+ a 1) 2))', 'a', '(- (- 7 2) 1)'},
	{'(= (+ a b) c)', 'a', '(- c b)'},
	{'(= c (+ a b))', 'a', '(- c b)'},
	{'(= 6 (* a 3))', 'a', '(/ 6 3)'},
	{'(= b (* (/ a 2) c))', 'a', '(* (/ b c) 2)'},
	{'(= c (+ (* a 2) (* b 2)) c)', 'a', '(/ (- c (* b 2)) 2)'}, -- c = a * 2 + b * 2. a?

	{'(= a (- b))', 'b', '(- a)'},
}

for i,test in ipairs(tests) do
	local eq = L(test[1])
	local name = L(test[2])
	local r = isoleer(eq, name)
	assert(U(r) == test[3], test[1]..' voor '..name .. ' was '..U(r)..' maar hoort '..test[3])
end
