require 'doe-bieb'
require 'exp'
require 'symbool'
require 'isoleer'

-- werkt op expressies
function inverteer(exp)
	-- makkelijk
	if isatoom(exp) then
		return inverteer_def[exp] or exp
	end

	-- compositie
	if exp.fn == '@' then
		return {fn='@', inverteer(exp[2]), inverteer(exp[1])}
	end

	local eq = {fn='=', 'A', exp}
	local term = isoleer0(eq, '_')
	--print("TERM", toexp(eq), toexp(term))

	return substitueer(term,'A','_')
end

function doe0(exp)
	-- bieb / symbool
	if exp == '[]' then return exp end
	if isatoom(exp) then return bieb[exp] or exp end

	-- functie
	if exp.fn == '->' then
		return function(a)
			local x,t = exp[1],exp[2]
			local f = substitueer(t, x, a)
			return doe0(f)
		end
	end

	-- infecteer
	local exp = map(exp, doe0)

	-- functioneel
	if isfn(exp.fn) then
		-- index
		if exp.fn.fn == '[]' and tonumber(exp[1]) then
			return exp.fn[exp[1]+1]
		end

		return substitueer(exp.fn, '_', exp[1])
	end

	-- f = a⁻¹
	if exp.fn == 'inverteer' then
		return inverteer(exp[1])
	end

	-- bieb
	if bieb[exp.fn] then
		return bieb[exp.fn](table.unpack(exp))
		-- local v = pcall(bieb[exp.fn], table.unpack(exp))
		-- if v then return v end
	end

	-- zelf
	if type(exp.fn) == 'function' then
		return exp.fn(table.unpack(exp))
	end

	return exp
end

if test then
	require 'ontleed'

	--local a = toexp(doe0(ontleed0('inverteer(sin ★)')))
	--assert(a == 'asin', a)

	--local a = toexp(doe0(ontleed0('inverteer(sin)')))
	--assert(a == 'asin', a)

	--local a = toexp(doe0(ontleed0('inverteer(sin ∘ cos ∘ tan)')))
	--assert(tostring(a) == '@(atan @(acos asin))', tostring(a))

	local code = [[
f = ★/2 ∘ sin
a = f⁻¹(2)
	]]

end
