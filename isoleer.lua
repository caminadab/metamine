require 'exp'

local predef = {
	sin = "asin",
	cos = "acos",
	tan = "atan",
	asin = "sin",
	acos = "cos",
	atan = "tan",
	wortel = {fn="^", "_", "2"},
}

inverteer_def = predef

-- rewrite (a + b = c, a) -> c - b
function isoleer0(eq,name)
	if eq.fn ~= '=' then return false end
	local flip = false
	while true do
		local eq0
		local l,r
		if not flip then
			l,r = eq[1],eq[2]
			flip = true
		else
			r,l = eq[1],eq[2]
			flip = false
		end
		if name == l then return r end
		if name == r then return l end

		if isfn(l) and #l == 1 then
			local f,a,x = l.fn,l[1],r
			local out
			local n = 0
			if bevat(a,name) then out = 0; n = n + 1 end
			if bevat(x,name) then out = 1; n = n + 1 end
			if bevat(f,name) then out = 2; n = n + 1 end
			if n ~= 1 then
				return false -- onoplosbaar
			end

			if f == '-' then
				-- x = - a
				if out == 0 then eq0 = {fn=':=', a, {fn='-', x}} end -- a = - x
				--if out == 1 then eq0 = {'=', x, {'-', a}} end -- x = - a
			elseif predef[f] then
				if out == 0 then eq0 = {fn=':=', a, predef[f]} end
			else
				-- x = f(a)
				--if out == 0 then eq0 = {'=', a, {{'^', f, '-1'}, x}} end -- a = (f^-1) x
				if out == 0 then eq0 = {fn=':=', a, {{fn='inverteer', f}, x}} end -- a = (f^-1) x
				--if out == 2 then eq0 = {'=', f, {'->', a, x}} end -- f = a -> x
			end
		end
		if isfn(l) and l.fn == '[]' then
			-- a = [x,b]
			for i,el in ipairs(l) do
				if bevat(el,name) then
					eq0 = {':=', el, {fn=r, i-1-1}}
					break
				end
			end
		end
		if isfn(l) and #l == 2 then
			local x,f,a,b = r,l.fn,l[1],l[2]
			local out
			local n = 0
			if bevat(a,name) then out = 0; n = n + 1 end
			if bevat(b,name) then out = 1; n = n + 1 end
			if bevat(x,name) then out = 2; n = n + 1 end
			if n ~= 1 then
				--log('FOUT',unlisp(eq),name)
				return false -- onoplosbaar
			end

			if f == '+' then
				-- x = a + b
				if out == 0 then eq0 = {fn=':=', a, {fn='-', x, b}} end -- a = x - b
				if out == 1 then eq0 = {fn=':=', b, {fn='-', x, a}} end -- b = x - a
				--if out == 2 then eq0 = {'=', x, {'+', a, b}} end -- x = a + b
			elseif f == '-' then
				-- x = a - b
				if out == 0 then eq0 = {fn=':=', a, {fn='+', x, b}} end -- a = x - b
				if out == 1 then eq0 = {fn=':=', b, {fn='-', x, a}} end -- b = x + a
				--if out == 2 then eq0 = {'=', x, {'-', a, b}} end -- x = a - b
			elseif f == '*' then
				-- x = a * b
				if out == 0 then eq0 = {fn=':=', a, {fn='/', x, b}} end -- a = x / b
				if out == 1 then eq0 = {fn=':=', b, {fn='/', x, a}} end -- b = x / a
				--if out == 2 then eq0 = {'=', x, {'*', a, b}} end -- x = a * b
			elseif f == '/' then
				-- x = a / b
				if out == 0 then eq0 = {fn=':=', a, {fn='*', x, b}} end -- a = x * b
				if out == 1 then eq0 = {fn=':=', b, {fn='/', a, x}} end -- b = a / x
				--if out == 2 then eq0 = {'=', x, {'/', a, b}} end -- x = a / b
			elseif f == '^' then
				-- x = a ^ b
				if out == 0 then eq0 = {fn=':=', a, {fn='^', x, {'/', '1', b}}} end -- a = x ^ (1 / a)
				if out == 1 then eq0 = {fn=':=', b, {fn='_', a, x}} end -- b = a _ x
				--if out == 2 then eq0 = {'=', x, {'^', a, b}} end -- x = a ^ b
			elseif f == '||' then
				-- x = a || b
				-- a = x (0..(#x-#b))
				if out == 0 then eq0 = {fn=':=', a, {fn=x, {fn='..', '0', {fn='-', {fn='#', x}, {fn='#',b}}}}} end
				if out == 1 then eq0 = {fn=':=', b, {fn=x, {fn='..', {fn='#', a}, {fn='#', x}}}} end -- b = x (#a..#x)
				--if out == 2 then eq0 = {'=', x, {'||', a, b}} end -- x = a || b
			else
				if print_niet_isoleerbaar then
					log('weet niet hoe te isoleren '..f)
				end
				return false -- kan operator niet oplossen
			end
		end

		if not eq0 and not flip then break end
		if eq0 then
			if verboos then print(tostring(toexp(eq)) .. ' -> '..tostring(toexp(eq))) end 
			eq = eq0
			flip = false
		end
	end
end

if test then
	verboos = true
	require 'ontleed'
	assert(isoleer0(ontleed0('a = b'), 'b') == 'a')
	assert(isoleer0(ontleed0('a = b'), 'a') == 'b')
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
