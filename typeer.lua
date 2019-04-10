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
;(^) :  (getal, getal) → getal
(#) :  lijst → int
([) : lijst
(>) :  (getal, getal) → bit
(≥) :  (getal, getal) → bit
(≤) :  (getal, getal) → bit
(<) :  (getal, getal) → bit
;(=) :  (iets, iets) → bit 
;(⇒) :  (bit,iets) → iets 
;(→) :  iets → (iets → iets)
(||) :  (lijst, lijst) → lijst
(en) : iets → bit

(iets → iets) : iets
(iets → int) : iets
iets^int : (iets → int)
int^int : (int → int)

lijst: iets^int
lijst int: lijst
lijst byte: lijst

data: lijst byte
teken: int
uit: tekst
tekst: lijst int

tijdstip : getal
int : getal
nu : tijdstip
cijfer : iets → bit
vind : (lijst, lijst) → int
tot : (lijst, int) → lijst
vanaf : (lijst, int) → lijst
deel : (lijst, (int, int)) → lijst
(∧) : iets → bit

(iets → getal) : (iets → iets)

herhaal : ((iets → iets) → (iets → iets))
som : (lijst getal) → getal ; TODO
(..) : (int, int) → lijst int
waarvoor : (lijst, (iets → bit)) → lijst
mod : (getal, getal) → getal

kleur : (getal, getal, getal)
(int, int, int) : (getal, getal, getal) ; hulpje
genormaliseerd : getal ;tussen 0 en 1
;kleur : (genormaliseerd, genormaliseerd, genormaliseerd)
rood : (getal, getal, getal)
groen : (getal, getal, getal)
blauw : (getal, getal, getal)
geel : (getal, getal, getal)
paars : (getal, getal, getal)
zwart: (getal, getal, getal)
wit: (getal, getal, getal)

; erg jammer dit
(int, int, int) : (getal, getal, getal)
(int, int, getal) : (getal, getal, getal)
(int, getal, int) : (getal, getal, getal)
(getal, int, int) : (getal, getal, getal)
(getal, getal, int) : (getal, getal, getal)
(getal, int, getal) : (getal, getal, getal)
(int, getal, getal) : (getal, getal, getal)

pos : (getal, getal)
pos : (int, int)
pos : (getal, int)
pos : (int, getal)
tekening : lijst
straal : kommagetal
cirkel : (pos,straal,(getal, getal, getal)) → (int, pos, straal, (getal, getal, getal))
rechthoek : (pos,pos,(getal, getal, getal)) → (int, pos, pos, (getal, getal, getal))
]]
function typeer0(exp)
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

local bieb,fouten = ontleed(bieb)
if fouten then error('biebfouten') end

function typeer(exp, t)
	local boom = exp
	local bron = exp.bron or '?'
	local typegraaf = stroom()
	typegraaf:link({}, "iets")
	local typegraaf = typegraaf:kopieer()

	local biebtypes = {} -- types: naam → type
	local types = {} -- eigen types: exp → type
	local naamtypes = {} -- hash → type
	local fouten = {} -- fouten: [fout...]
	local oorzaakloc = {} -- exp → loc
	-- collision
	-- collisie: { bericht = "'a' moet zijn 'int', maar is 'tekst', exp = {bronpos, waarde}, fout = {bronpos, type}, moet = {bronpos, type} }

	-- bieb
	for i,v in ipairs(bieb) do
		local symbool = exphash(v[1])
		local type = v[2]
		biebtypes[exphash(v[1])] = type
		typegraaf:link(set(exphash(type)), symbool)
		--print('BIEB', exphash(v[1]), exphash(type))
	end

	-- eigen :)
	for i, exp in ipairs(exp) do -- boompairsdfs(exp, t) do
		if isfn(exp) and isatoom(exp.fn) and exp.fn.v == ':' then
			local v = exp
			local symbool = exphash(v[1])
			local type = v[2]
			biebtypes[exphash(v[1])] = type
			typegraaf:link(set(exphash(type)), symbool)
		end
	end

	-- verenigt types
	local function weestype(exp, type, typeoorzaakloc)
		local T,ol
		--print('wees type', exphash(exp) .. ' : '..exphash(type), typeoorzaakloc and loctekst(typeoorzaakloc))
		if types[exp] and exphash(types[exp]) ~= exphash(type) then
			local a = exphash(type)
			local b = exphash(types[exp])

			-- type ⊂ T(exp)
			-- oftewel: type is specifieker
			if typegraaf:stroomopwaarts(a, b) then
				T = types[exp] or error('geen type')
			-- T(exp) ⊂ type
			-- oftewel: T is specifieker
			elseif typegraaf:stroomopwaarts(b, a) then
				T = type or error('geen type')
			else
				-- c.code@7:11-12: "a" is "int" maar moet zijn "bit"
				local isloc = oorzaakloc[exp] or exp.loc
				local moetloc = typeoorzaakloc or oorzaakloc[exphash(exp)]
				local msg = string.format('%s@%s: Typefout: "%s" is "%s" (bron: %s) maar moet zijn "%s" (bron: %s)',
					bron, loctekst(exp.loc), -- locatie
					combineer(exp), -- exp
					combineer(types[exp]), -- echte type
					loctekst(isloc), -- echte type bron
					combineer(type), -- wordt verwacht als
					loctekst(moetloc) -- "" "" bron
				)
				-- kort: exp, istype, moettype
				local kort = '"%s" is "%s" maar moet zijn "%s"'
				if not fouten[msg] then
					print(msg)
					fouten[#fouten+1] = {loc = exp.loc, msg = msg, kort = kort, isloc = isloc, moetloc = moetloc}
					fouten[msg] = true
				end
				--print('Typegraaf:')
				--print(typegraaf:tekst())
				return types,fouten
			end
		else
			T,ol = type,exp.loc
		end
		-- ECHT TYPEREN!
		if T and not types[exp] or exphash(types[exp]) ~= exphash(T) then
			types[exp] = T
			naamtypes[exphash(exp)] = T
			oorzaakloc[exphash(exp)] = typeoorzaakloc or ol or exp.loc
			oorzaakloc[exp] = typeoorzaakloc or ol or exp.loc
			typegraaf:link(set'iets', exphash(T))
			if verboos then
				print('TYPEER', exphash(exp)..': '..exphash(T))
			end
		end
	end

	-- makkelijke types
	for exp in boompairsdfs(exp, t) do
		local T
		if tonumber(exp.v) and exp.v % 1 == 0 then T = X'int'
		elseif tonumber(exp.v) then T = X'kommagetal'
		elseif exp.tekst then
			T = X'tekst'
		elseif isfn(exp) and exp.fn.v == '[]' then
			T = X'lijst'
		elseif biebtypes[exphash(exp)] then
			T = biebtypes[exphash(exp)] -- voorgedefinieerd is makkelijk
		end
		if T then
			if verboos then print('MAKKELIJK', exphash(exp), exphash(T))  end
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

			-- deze exp heeft al een type
			if naamtypes[exphash(exp)] then
				local T = naamtypes[exphash(exp)] -- voorgedefinieerd is makkelijk
				weestype(exp, T, oorzaakloc[exphash(exp)])

			elseif isfn(exp) then
				local fn,f,a,b = exp.fn, exp.fn.v, exp[1], exp[2]

				-- speciaal voor '='
				if f == '=' then
					local ta, tb = types[a], types[b]
					local tah, tbh = ta and exphash(ta), tb and exphash(tb)
					if ta and tb and tah ~= tbh then
						-- b : a
						if typegraaf:stroomopwaarts(tah, tbh) then
							weestype(a, types[b], oorzaakloc[exp])
						-- a : b
						elseif typegraaf:stroomopwaarts(tbh, tah) then
							weestype(b, types[a], oorzaakloc[b])
						else
							fouten[#fouten+1] = {loc = exp.loc, msg = msg}
							local msg = string.format('%s@%s: Typefout: links is "%s" (bron: %s), rechts is "%s" (bron: %s)',
								bron, loctekst(exp.loc), -- locatie
								combineer(types[a]), -- links
								loctekst(oorzaakloc[a] or a.loc), -- links bron
								combineer(types[b]), -- rechts
								loctekst(oorzaakloc[b] or b.loc) -- rechts bron
							)
							if not fouten[msg] then
								print(msg)
								fouten[#fouten+1] = {loc = exp.loc, msg = msg}
								fouten[msg] = true
							end
						end
					elseif types[a] then weestype(b, types[a], exp.loc) ; oorzaakloc[b] = exp.loc
					elseif types[b] then weestype(a, types[b], exp.loc) ; oorzaakloc[a] = exp.loc
					end
					if types[a] and types[b] then
						weestype(exp, X'bit') ; oorzaakloc[exp] = exp.fn.loc
					end
				end
		
				-- speciaal voor '⇒'
				if f == '=>' then
					weestype(a, X'bit', exp.fn.loc)
					if types[b] then weestype(exp, types[b], oorzaakloc[b]) end 
				end

				-- speciaal voor ',' (tupel)
				-- ℝ × ℝ
				if f == ',' then
					T = {fn=X','}
					for i,v in ipairs(exp) do
						if types[v] then
							T[i] = types[v]
						else
							T = nil
							break
						end
					end
					if T then
						weestype(exp, T, exp.loc)
					end
				end
		
				-- speciaal voor '→'
				if f == '->' then -- (a → b) : (
					if naamtypes[exphash(a)] and types[b] then
						weestype(a, naamtypes[exphash(a)]) ; oorzaakloc[a] = oorzaakloc[exphash(a)]
						weestype(b, types[b]) ; oorzaakloc[b] = oorzaakloc[b] or fn.loc
						weestype(exp, X('->', naamtypes[exphash(a)], types[b])) ; oorzaakloc[exp] = fn.loc
					elseif types[a] and types[b] then
						weestype(exp, X('->', types[a], types[b])) ; oorzaakloc[exp] = exp.loc
					elseif types[b] then
						--weestype(exp, X('->', 'iets', types[b])) ; oorzaakloc[exp] = b.loc
					end
				end
			end

			if tfn and #tfn == 2 and tfn.fn.v == '->' then
				assert(#tfn == 2, exphash(tfn))

				-- niet het gewenste aantal argumenten
				local nargs = #exp
				-- local unpacking
				if isfn(exp) and isfn(exp[1]) and exp[1].fn.v == ',' then nargs = #exp[1] end
				if N(tfn) ~= nargs and N(tfn) ~= math.huge then
					local msg = string.format('%s@%s: Typefout: "%s" heeft %d argumenten maar moet er %d hebben',
						bron, loctekst(exp.loc),
						combineer(exp),
						nargs, N(tfn)
					)
					local kort = string.format('"%s" heeft %d argumenten maar moet er %d hebben',
						combineer(exp), nargs, N(tfn))
					if not fouten[msg] then
						print(msg)
						fouten[#fouten+1] = {loc = exp.loc, msg = msg, kort = kort}
						fouten[msg] = true
					end
				end
		
				if N(tfn) ~= math.huge then
					for i = 1, N(tfn) do
						--print('  ARG', exphash(exp[i]), exphash(A(tfn, i)), loctekst(exp[i].loc))
						local arg = exp[i]
						if isfn(exp) and isfn(exp[1]) and exp[1].fn.v == ',' then arg = exp[1][i] end
						weestype(arg, A(tfn, i), exp.fn.loc)
					end
				end
				--print('  RET', exphash(tfn[2]))
				weestype(exp, tfn[2], exp.fn.loc)
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

	return types, fouten
end
