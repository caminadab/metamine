require 'set'
require 'func'


--[[
∆ 3 = (start => 3)
∆ nu = (tik => +1/freq)
∆ (a en b) = (∆a unie ∆b)
∆ (a := b) = (∆a => (a := (a deltacomp ∆b)))
∆ (a + b) = ∆a co ∆b
∆ (a = b) = (∆a en ∆b => (a = b))
∆ (a -> b) = a -> ∆b
∆ (udp-in p)  = { udp-open(p) => [], udp-leesbaar(p)    => udp-lees(p) }
∆ (udp-uit p) = { udp-open(p) => ja, udp-schrijfbaar(p) => ja          }
∆ udp-uit     = { p -> ∆ (udp-uit p)                                   }

udp-in(p)       = { udp-lees }
udp-lees(p)     = [ander, bericht]
udp-schrijf(p)  = [ander, bericht]

VOORBEELD: ∆(a = 3)


WAARDERING:
berekenbare multiset
]]

function delta(exp)
	_G.print('∆ '..unlisp(exp))
	local fn = isexp(exp) and exp[1]
	local num = tonumber(exp)
	local a,b = fn and exp[2], fn and exp[3]

	-- ∆ 3 = (start => 3)
	if num then
		return {'=>', 'start', '3'}
	end

	-- ∆ nu = (tik => +dt)
	if exp == 'nu' then
		return 'tik'
	end
  
	-- ∆ (a en b) = (∆a unie ∆b)
	if fn == 'en' then
		return binop(staart(exp), unie)
	end
		
	-- ∆ (a := b) = (∆a => (a := (a deltacomp ∆b)))
	if fn == '=' then
		local an = {'deltacomp', a, delta(b) }
		local w = {':=', a, an}
		return {'=>', delta(a), w}
	end

	-- ∆ (a + b) = ∆a co ∆b
	if fn == '+' then
		return {'co', delta(a), delta(b) }
	end

	-- ∆ (a = b) = (∆a en ∆b => (a = b))
	if fn == '=' then
		local als = {'en', delta(a), delta(b) }
		return {'=>', als, {'=', a, b}}
	end

	-- ∆ (a -> b) = a -> ∆b
	if fn == '->' then
		return {'->', a, delta(b) }
	end

	-- ∆ (udp-in a)  = { udp-open(a) => [], udp-leesbaar(a)    => udp-lees(a) }
	if fn == 'udp-in' then
		return {'co',
			{'=>', {'udp-open',a}, {'{}'} },
			{'=>', {'udp-leesbaar',a}, {'udp-lees',a} },
		}
	end

	-- ∆ (udp-uit p) = { udp-open(p) => ja, udp-schrijfbaar(p) => ja          }
	if fn == 'udp-uit' then
		return {'co',
			{'=>', {'udp-open',a}, 'ja' },
			{'=>', {'udp-schrijfbaar',a}, 'ja'},
		}
	end

	-- ∆ udp-uit     = { p -> ∆ (udp-uit p)                                   }
	if exp == 'udp-uit' then
		do return 'ja' end -- HIER
		return {'->', '_p', delta({'udp-uit', '_p'}) }
	end

	error('onbekend: ∆ '..unlisp(exp))
end

function deltastroom(stroom)
	local deltas = map(stroom, delta)
	return binop(deltas, unie)
end

