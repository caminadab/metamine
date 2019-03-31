require 'exp'
require 'stroom'
require 'infix'

--[[
teken^int ⊂ (int → teken)
tekst = teken^int

]]

function isconstant(v)
	if isatoom(v) then
		if tonumber(v.v) and math.modf(tonumber(v.v), 1) == 0 then
			v.is = {int = true, getal = true}
			v.val = tonumber(v.v)
			return true
		elseif tonumber(v.v) then
			v.is = {getal = true}
			v.val = tonumber(v.v)
			return true
		elseif bieb[v.v] then
			v.val = bieb[v.v]
			v.is = {iets = true}
			return true
		end
	else
		local c = true
		if not isconstant(v.fn) then
			c = false
		end
		for i,v in ipairs(v) do
			if not isconstant(v) then
				c = false
			end
		end
	end
			
	return false
end

local bieb = [[
getal : iets
kommagetal : getal
int : getal
ja : bit
nee : bit
(+) :  (getal, getal) → getal
(-) :  (getal, getal) → getal
(*) :  (getal, getal) → getal
(/) :  (getal, getal) → getal
(^) :  (getal, getal) → getal
(#) :  (iets^int) → int
([) : iets → iets^int
(<=) :  (getal, getal) → bit
(>=) :  (getal, getal) → bit
(>) :  (getal, getal) → bit
(<) :  (getal, getal) → bit
;(=) :  (iets, iets) → bit 
;(⇒) :  (bit,iets) → iets 
;(→) :  iets → (iets → iets)
(||) :  (iets^int, iets^int) → iets^int
(iets → iets) : iets
(iets → int) : iets
iets^int : (iets → int)
int^int : (int → int)

data : int → byte
teken : int
(int → teken) : (int → int)
tekst : (iets → tekst)
uit : tekst
tijdstip : getal
int : getal
nu : tijdstip
cijfer : iets → bit
vind : (iets^int, iets^int) → int
tot : (iets^int, int) → iets^int
vanaf : (iets^int, int) → iets^int
deel : (iets^int, iets^int) → int
(∧) : iets → bit

(iets → getal) : (iets → iets)

herhaal : ((iets → iets) → (iets → iets))
som : (int → getal) → getal
(..) : (int, int) → int^int
waarvoor : ((int → iets), (iets → bit)) → (int → iets)
mod : (getal, getal) → getal

tekening : (pos, vorm, kleur)
straal : getal
cirkel : vorm
cirkel : straal
genormaliseerd : getal ;tussen 0 en 1
kleur : genormaliseerd³
rood : kleur
groen : kleur
blauw : kleur
geel : kleur
paars : kleur
]]
function typeer(exp)
	local t = {}
	-- type = boom | set van types
	--   gebruikt set van types
	-- t = exp → type
	for v in boompairsdfs(exp) do
		if isconstant(v) then
			v.val = doe(v)
		end
	end
end

local bieb = ontleed(bieb)

function typeer(exp, t)
	local boom = exp
	local bron = exp.bron or '?'
	local typegraaf = stroom()
	typegraaf:link({}, "iets")
	local typegraaf = typegraaf:kopieer()

	local biebtypes = {} -- types: naam → type
	local types = {} -- eigen types: exp → type
	local naamtypes = {} -- hash → type

	-- bieb
	for i,v in ipairs(bieb) do
		local symbool = exphash(v[1])
		local type = v[2]
		biebtypes[exphash(v[1])] = type
		typegraaf:link(set(exphash(type)), symbool)
		--print('BIEB', exphash(v[1]), exphash(type))
	end

	-- eigen :)
	for exp in boompairsdfs(exp, t) do
		if isfn(exp) and isatoom(exp.fn) and exp.fn.v == ':' then
			local v = exp
			local symbool = exphash(v[1])
			local type = v[2]
			biebtypes[exphash(v[1])] = type
			typegraaf:link(set(exphash(type)), symbool)
		end
	end

	-- verenigt types
	local function weestype(exp, type)
		local T
		if types[exp] and exphash(types[exp]) ~= exphash(type) then
			local a = exphash(type)
			local b = exphash(types[exp])

			-- type ⊂ T(exp)
			-- oftewel: type is specifieker
			if typegraaf:bereikbaar_disj(a, b) then
				T = types[exp] or error('geen type')
			-- T(exp) ⊂ type
			-- oftewel: T is specifieker
			elseif typegraaf:bereikbaar_disj(b, a) then
				T = type or error('geen type')
			else
				-- c.code@7:11-12: "a" is "int" maar moet zijn "bit"
				local msg = string.format('%s@%s: "%s" is "%s" maar moet zijn "%s"',
					bron, loctekst(exp.loc),
					combineer(exp),
					combineer(type), combineer(types[exp])
				)
				print(msg)
				print('Typegraaf:')
				print(typegraaf:tekst())
				return types,false
			end
		else
			T = type
		end
		if T and not types[exp] or exphash(types[exp]) ~= exphash(T) then
			types[exp] = T
			naamtypes[exphash(exp)] = T
			typegraaf:link(set'iets', exphash(T))
			if verboos then
				print('TYPEER', exphash(exp)..'['..loctekst(exp.loc)..'] : '..exphash(T))
			end
		end
	end

	-- makkelijke types
	for exp in boompairsdfs(exp, t) do
		local T
		if tonumber(exp.v) and math.abs(math.modf(tonumber(exp.v), 1)) < 1e-9  then T = X'int'
		elseif tonumber(exp.v) then T = X'kommagetal'
		elseif biebtypes[exphash(exp)] then
			T = biebtypes[exphash(exp)] -- voorgedefinieerd is makkelijk
		end
		if T then
			print('MAKKELIJK', exphash(exp), exphash(T)) 
			types[exp] = T
			typegraaf:link(set('iets'), exphash(T))
		end
	end

	-- verkrijg aantal argumenten
	local function N(exp)
		assert(exp.fn.v == '->')
		if isatoom(exp[1]) and exp[1].v == 'iets' then
			return math.huge
		end
		if isfn(exp[1]) and exp[1].fn.v == ',' then
			return #exp[1]
		end
		return 1
	end

	-- verkrijg nde argument van functie
	local function A(exp, i)
		assert(exp.fn.v == '->')
		if isfn(exp[1]) and exp[1].fn.v == ',' then
			return exp[1][i]
		end
		if i ~= 1 then return nil end
		return exp[1]
	end

	for i=1,4 do

	-- rest van de types
	local T = {}
	for exp in boompairsdfs(exp, to) do
		if true or not types[exp] then

			local tfn = types[exp.fn]

			if naamtypes[exphash(exp)] then
				local T = naamtypes[exphash(exp)] -- voorgedefinieerd is makkelijk
				weestype(exp, T)

			elseif isfn(exp) then
				local f,a,b = exp.fn.v, exp[1], exp[2]

				-- speciaal voor '='
				if f == '=' then
					if types[a] then weestype(b, types[a])
					elseif types[b] then weestype(a, types[b])
					end
					weestype(exp, X'bit')
				end
		
				-- speciaal voor '⇒'
				if f == '=>' then
					weestype(exp[1], X'bit')
					if types[b] then weestype(exp, types[b]) end 
				end
		
				-- speciaal voor '→'
				if f == '->' then -- (a → b) : (
					if naamtypes[exphash(a)] and types[b] then
						weestype(a, naamtypes[exphash(a)])
						weestype(b, types[b])
						weestype(exp, X('->', naamtypes[exphash(a)], types[b]))
					elseif types[a] and types[b] then
						weestype(exp, X('->', types[a], types[b]))
					elseif types[b] then
						weestype(exp, X('->', 'iets', types[b]))
					end
				end
			end

			if tfn and #tfn == 2 then
				assert(#tfn == 2, exphash(tfn))

				-- niet het gewenste aantal argumenten
				if N(tfn) ~= #exp and N(tfn) ~= math.huge then
					local msg = string.format('%s@%s: "%s" heeft %d argumenten maar moet er %d hebben',
						bron, loctekst(exp.loc),
						combineer(exp),
						#exp, N(tfn)
					)
					print(msg)
					print(exphash(tfn))
					print(exphash(exp))
					os.exit()
				end
		
				if N(tfn) ~= math.huge then
					for i = 1, N(tfn) do
						print('  ARG', exphash(exp[i]), exphash(A(tfn, i)), loctekst(exp[i].loc))
						weestype(exp[i], A(tfn, i))
					end
				end
				print('  RET', exphash(tfn[2]))
				weestype(exp, tfn[2])
			end
		end
	end

	end

	if verboos then
		print()
		print('# Types')
		for exp, type in pairs(types) do
			print(exphash(exp)..'\t: '..exphash(type))
		end
		print()
	end

	print('TYPERING GESLAAGD - PROGRAMMA IS ZINVOL')

	return types, true
end
