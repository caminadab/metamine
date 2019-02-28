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

	-- TODO exp logica zodat alles inverteren

	-- compositie
	if exp.fn == '@' then
		return {fn='@', inverteer(exp[2]), inverteer(exp[1])}
	end

	local eq = {fn='=', 'A', exp}
	local term = isoleer0(eq, '_')
	--print("TERM", toexp(eq), toexp(term))

	return substitueer(term,'A','_')
end

-- PROXY
--[[
function doe(exp)
	local v = doe0(exp)
	if verboos and not isatoom(exp) then
		local a,b = toexp(exp), toexp(v)
		if a ~= b then
			print('DOE', a, b)
		end
	end
	return v
end
]]

require 'plet'
function doe(exp)
	local _,t,naam = plet(exp)
	local map = {}
	local laatste
	local stapel = {}

	for i,w in ipairs(t) do
		local naam = naam(i)
		if verboos then io.write(naam, '\t', tostring(toexp(w)), '\t\t') end

		-- indirectie
		local waarde = {}
		for i,naam in pairs(w) do
			if map[naam] ~= nil then
				waarde[i] = map[naam]
			elseif bieb[naam] ~= nil then
				waarde[i] = bieb[naam]
			else
				waarde[i] = naam
			end
		end

		if type(waarde.fn) == 'table' then
			r = waarde.fn[waarde[1]+1]
		else
			local ok
			ok,r = pcall(waarde.fn, table.unpack(waarde))
			if not ok then r = false end
		end
		map[naam] = r
		laatste = r
		if verboos then io.write('= ', tostring(toexp(r)), '\n') end
	end
	--return map[naam(#map)]
	--print("L", toexp(laatste))
	return laatste 
end

function doe0(exp)
	local doe = doe0
	-- bieb / symbool
	if exp == '[]' then return exp end
	if isatoom(exp) then
		if bieb[exp] ~= nil then
			return bieb[exp]
		else
			return exp
		end
	end

	-- functie
	if exp.fn == '->' then
		return function(a)
			local x,t = exp[1],exp[2]
			local f = substitueer(t, x, a)
			return doe(f)
		end
	end

	-- infecteer
	local exp = map(exp, doe)

	-- inverteer
	if exp.fn == 'inverteer' then
		return inverteer(exp[1])
	end

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
	-- x -> x + 1
	if type(exp.fn) == 'function' then
		return exp.fn(table.unpack(exp))
	end

	return exp
end

if test then
	require 'ontleed'

	--local a = toexp(doe(ontleed0('inverteer(sin ★)')))
	--assert(a == 'asin', a)

	--local a = toexp(doe(ontleed0('inverteer(sin)')))
	--assert(a == 'asin', a)

	--local a = toexp(doe(ontleed0('inverteer(sin ∘ cos ∘ tan)')))
	--assert(tostring(a) == '@(atan @(acos asin))', tostring(a))

	local code = [[
f = ★/2 ∘ sin
a = f⁻¹(2)
	]]

end
