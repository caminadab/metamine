require 'exp'
require 'stroom'
require 'combineer'
require 'typegraaf'

require 'ontleed'
require 'oplos'
require 'fout'

--[[
teken^int ⊂ (int → teken)
tekst = teken^int

bug:
f(x: int) : int zorgt niet voor f = int → int

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
		if not isconstant(v.f) then
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

-- lees biebgraaf
local bieb,fouten = ontleed(bestand 'bieb/std.code', 'bieb/std.code')
local bieb = {}
if fouten then map(fouten, function(fout) print(fout2ansi(fout)) end) end

function typeer(exp)
	if verbozeTypes then
		print()
		print('== Types ==')
	end

	local typegraaf = maaktypegraaf()

	local biebtypes = {}
	local types = {} -- eigen types: exp → type
	local naamtypes = {} -- hash → type
	local fouten = {} -- fouten: [fout...]
	local oorzaakloc = {} -- exp → loc
	-- collision
	-- collisie: { bericht = "'a' moet zijn 'int', maar is 'tekst', exp = {bronpos, waarde}, fout = {bronpos, type}, moet = {bronpos, type} }

	-- bieb
	for i,v in ipairs(bieb) do
		local type,super = v[1],v[2]
		typegraaf:link(type, super)
		naamtypes[moes(type)] = super
		biebtypes[moes(type)] = super -- types: naam → type
		oorzaakloc[moes(type)] = v.loc
	end

	local code = exp[1].code

	-- verenigt types
	local function weestype(exp, type, typeoorzaakloc)
		local exp = maaktype(exp, typegraaf)
		local type = maaktype(type, typegraaf)
		if type.v == 'iets' then return end
		local T,S,ol -- Type, Super, Oorzaakloc
		if types[exp] and moes(types[exp]) ~= moes(type) then
			local a = type
			local b = types[exp]

			-- type ⊂ T(exp)
			-- oftewel: oude is specifieker
			if typegraaf:issubtype(b, a) then
				T = b or error('geen type')
			--[[
				T = a -- doe hem niet
				local msg = typeerfout(
					exp.loc,
					"onzekere conversie van {exp} naar {exp}",
					a,
					b
				)
				if not fouten[msg] then
					fouten[#fouten+1] = {loc = exp.loc, msg = msg}
					fouten[msg] = true
				end
				]]
			-- T(exp) ⊂ type
			-- oftewel: nieuwe is specifieker
			elseif typegraaf:issubtype(a, b) then
				T = a or error('geen type')
			elseif typegraaf:unie(a, b) then
				T = typegraaf:unie(a, b)
			else
				-- c@7:11-12: "a" is "int" maar moet "bit" zijn
				local isloc = oorzaakloc[exp] or exp.loc
				local moetloc = typeoorzaakloc or oorzaakloc[moes(exp)]
				--assert(code)
				code = code or ''
				local fout = typeerfout(
					exp.loc,
					"{code} is {exp} ({loc}) maar moet {exp} zijn ({loc})",
					locsub(code, exp.loc),
					types[exp], isloc,
					type, moetloc
				)
				local a = fout2ansi(fout)
				if not fouten[a] then
					fouten[#fouten+1] = fout
					fouten[a] = true
				end
				return types,fouten
			end
		else
			T,ol = type,exp.loc
		end
		-- ECHT TYPEREN!
		if T and not types[exp] or moes(types[exp]) ~= moes(T) then
			types[exp] = T
			naamtypes[moes(exp)] = T
			oorzaakloc[moes(exp)] = typeoorzaakloc or ol or exp.loc
			oorzaakloc[exp] = typeoorzaakloc or ol or exp.loc
			typegraaf:link(T)
			if verbozeTypes then
				local t = typeoorzaakloc or ol or exploc
				local s = t and '\t(' ..ansi.underline.. (loctekst(t) or '')..ansi.normal..')' or ''

				--print('TYPEER', moes(exp)..': '..moes(T))
				if exp.loc and exp.loc.bron and exp.loc.bron:sub(1,5) ~= 'bieb/' then
					print(combineer(exp)..'\t: '..combineer(T)..s)
				end
			end
		end
	end

	-- eigen :)
	for i, exp in ipairs(exp) do
		if isfn(exp) and isatoom(exp.f) and exp.f.v == ':' then
			local val, type = exp[1],exp[2]
			weestype(val, type, exp.loc)
		end
	end

	-- makkelijke types
	for exp in boompairsdfs(exp, t) do
		local T,S
		if tonumber(exp.v) and exp.v % 1 == 0 then
			local n = tonumber(exp.v)
			--T = exp
			if n < 256 and false then
				T = X'byte'
			else
				T = X'int'
			end
		elseif tonumber(exp.v) then
			--T = X'kommagetal'
			T = X'getal'
		elseif isfn(exp) and fn(exp) == '[]u' then
			weestype(exp.f, X'tekens')
			weestype(exp, X('tekst'))
		elseif isfn(exp) and fn(exp) == '{}' then
			T = X'set'
		elseif isfn(exp) and fn(exp) == ',' then
			--T = X'tupel'
			local T = {f=X'tupel'}
			local ok = true
			for i=1,#exp do
				local t = types[exp[i]]
				if not t then
					ok = false
					break
				end
				T[i] = t
			end
			if not ok then
				T = nil
			end
		elseif biebtypes[moes(exp)] then
			T = biebtypes[moes(exp)] -- voorgedefinieerd is makkelijk
			oorzaakloc[exp] = oorzaakloc[moes(exp)]
		end
		if T then
			T = maaktype(T, typegraaf)
			local t = oorzaakloc[moes(exp)]
			local s = '\t(' ..ansi.underline.. (t and loctekst(t) or '')..ansi.normal..')'
			if verbozeTypes and exp.loc and exp.loc.bron and exp.loc.bron:sub(1,5) ~= 'bieb/' then
				print(moes(exp), moes(T), s)
			end
			types[exp] = T
			typegraaf:link(T, S)
		end
	end
	if verbozeTypes then print() end

	-- verkrijg aantal argumenten
	local function N(exp)
		assert(exp.f.v == '→')
		if isatoom(exp[1]) and exp[1].v == 'iets' then
			return math.huge
		end
		if isfn(exp[1]) and exp[1].f.v == ',' then
			return #exp[1]
		end
		return 1
	end

	local function ARG(exp, i)
		if #exp == 1 and fn(exp[1]) == ',' then
			return exp[1][i]
		else
			return exp[i]
		end
	end

	-- verkrijg nde argument van functie
	local function A0(exp, i)
		assert(exp.f.v == '→')
		if isfn(exp[1]) and exp[1].f.v == ',' then
			return exp[1][i]
		end
		if i ~= 1 then return nil end
		return exp[1]
	end

	for i=1,5 do

	-- rest van de types
	local T = {}
	for exp in boompairsdfs(exp, to) do
		if true or not types[exp] then

			local tfn = types[exp.f]

			if #exp == 1 and isvar(exp.f) and not types[exp.f] and types[exp[1]] and types[exp] then
				-- typeer de functie zelf
				-- f(2) = 3 → f = getal → getal
				local functype = {f=X'→', types[exp[1]], types[exp]}
				weestype(exp.f, functype, exp.loc)
			end

			-- deze exp heeft al een type
			if naamtypes[moes(exp)] and naamtypes[moes(exp)] ~= 'iets' then
				local T = naamtypes[moes(exp)] -- voorgedefinieerd is makkelijk
				weestype(exp, T, oorzaakloc[moes(exp)])

			elseif isfn(exp) then
				local fn,f,a,b = exp.f, exp.f.v, exp[1], exp[2]

				-- speciaal voor 'herhaal'
				if f == 'herhaal' and types[a] then
					local ta, tb = types[a], types[b]
					weestype(tb, X'int', exp.f.loc)
					weestype(exp, ta, exp.f.loc)
					weestype(exp.f, X'→')

				-- speciaal voor 'map'
				-- [1,2,3] map sin  :  (int^int, int → getal) → getal^int
				-- map: (T:collectie)(A), (A → B) → T(B)
				elseif f == 'map' and types[a] and types[b] then
					local atype =X('verzameling', types[a]:paramtype('verzameling'))
					local btype = X('verzameling', types[b[2]])
					weestype(a, atype)
					weestype(exp, btype)
					--print('ATYPE', e2s(atype))
					--print('BTYPE', e2s(btype))

				-- speciaal voor 'xx'
				elseif f == '×' and types[a] and types[b] then
					local type = X('lijst', X('tupel', types[a]:paramtype('lijst'), types[b]:paramtype('lijst')))
					weestype(exp, type)
					weestype(fn, 'dinges')

				-- speciaal voor '_'
				elseif f == '_' and types[a] and types[b] then
					local type = types[a]:paramtype('lijst')
					weestype(exp, type)
					weestype(b, X'nat')
					--weestype(a, X'lijst')

				elseif isfn(exp) and f == '[]' then
					--T = X'lijst'
					T = typegraaf.iets
					for i=1,#exp do
						local t = types[exp[i]]
						if not t then break end
						T = typegraaf:unie(T, t)
						--print('UNIE', e2s(T))
						if not T then break end
					end
					if T and T.v ~= 'iets' then T = {f=X'lijst', T}
					--if true or T and T.v ~= 'iets' then T = X('^', T, #exp)
					else T = nil end
					if T ~= nil then
					weestype(exp, T)
					end

				elseif f == '‖' and types[a] and types[b] then
					local asub = types[a]:paramtype('lijst')
					local bsub = types[a]:paramtype('lijst')
					local sub = typegraaf:unie(asub, bsub)
					local type = X('lijst', sub)
					weestype(exp, type)
					weestype(fn, X'ok')

				-- speciaal voor '[]u'
				elseif f == '[]u' then
					weestype(exp, X'tekst')

				-- speciaal voor 'componeer'
				-- [1,2,3] map sin  :  (int^int, int → getal) → getal^int
				elseif f == '@' and types[a] and types[b] then
					-- TODO check
					weestype(exp, X('→', types[a][1], types[b][2]))
					weestype(fn, X'ok')

				-- speciaal voor '='
				elseif f == '=' then
					local ta, tb = types[a], types[b]
					local tah, tbh = ta and moes(ta), tb and moes(tb)
					if ta and tb and tah ~= tbh then
						-- b : a
						if typegraaf:issubtype(tb, ta) then
							weestype(a, types[b], oorzaakloc[exp])
						-- a : b
						elseif typegraaf:issubtype(ta, tb) then
							weestype(b, types[a], oorzaakloc[b])
						else
							local aloc = oorzaakloc[a] or a.loc
							local bloc = oorzaakloc[b] or b.loc
							local fout = typeerfout(exp.loc, '{code} is {exp} ({loc}), {code} is {exp} ({loc})',
								locsub(code, a.loc),
								types[a], aloc,
								locsub(code, b.loc),
								types[b], bloc
							)
							local a = fout2ansi(fout)
							if not fouten[a] then
								fouten[#fouten+1] = fout
								fouten[a] = true
							end
						end
						weestype(fn, 'ok')
					elseif types[a] then weestype(b, types[a], exp.loc) ; oorzaakloc[b] = exp.loc
					elseif types[b] then weestype(a, types[b], exp.loc) ; oorzaakloc[a] = exp.loc
					end
					if types[a] and types[b] then
						weestype(exp, X'bit') ; oorzaakloc[exp] = exp.f.loc
					end
		
				-- speciaal voor '⇒'
				elseif f == '=>' then
					weestype(a, X'bit', exp.f.loc)
					weestype(fn, X'ok', exp.f.loc)
					if types[b] then weestype(exp, types[b], oorzaakloc[b]) end 

				-- speciaal voor ',' (tupel)
				-- ℝ × ℝ
				elseif f == ',' then
					T = {f=X','}
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
				if f == '→' then -- (a → b) : (
					-- argumenten
					--if isfn(fn) and fn.f.v = ',' then
						--for 

					-- functie
					if naamtypes[moes(a)] and types[b] then
						weestype(a, naamtypes[moes(a)], oorzaakloc[moes(a)])
						weestype(b, types[b], oorzaakloc[b] or fn.loc)
						weestype(exp, X('→', naamtypes[moes(a)], types[b]), fn.loc)
					elseif types[a] and types[b] then
						weestype(exp, X('→', types[a], types[b])) ; oorzaakloc[exp] = exp.loc
					elseif types[b] then
						--weestype(exp, X('→', 'iets', types[b])) ; oorzaakloc[exp] = b.loc
					end
				end

			end


			-- nog koeler doen met ranges
			if #exp == 1 and types[exp.f] and typegraaf:issubtype(types[exp.f], X'^') then
				local elmin,elmax = typegraaf:paramtype(types[exp.f], X'^')
				local bereik = X('..', '0', elmax)
				typegraaf:link(bereik, X'nat')
				weestype(exp[1], bereik, oorzaakloc[exp.f])
				weestype(bereik, X'nat', exp.loc) -- TODO loc
			end

			-- is dit "tekst"?
			if #exp == 1 and types[exp.f] and typegraaf:issubtype(types[exp.f], X'tekst') then
				local eltype = typegraaf:paramtype(types[exp.f], X'lijst')
				weestype(exp, X'teken', exp.loc) -- TODO loc
				--weestype(exp[1], X'nat', exp.loc) -- TODO loc

			-- koel doen met lijst indices
			elseif #exp == 1 and types[exp.f] and typegraaf:issubtype(types[exp.f], X'lijst') then
				local eltype = typegraaf:paramtype(types[exp.f], X'lijst')
				weestype(exp, eltype, exp.loc) -- TODO loc
				--weestype(exp[1], X'nat', exp.loc) -- TODO loc
			end

			if tfn and #tfn == 2 and fn(tfn) == '→' then

				-- niet het gewenste aantal argumenten
				local nargs = #exp
				-- local unpacking
				if isfn(exp) and isfn(exp[1]) and exp[1].f.v == ',' then nargs = #exp[1] end
				if false and N(tfn) ~= nargs and N(tfn) ~= math.huge then
					local msg = typeerfout(exp.loc, '{code} heeft {int} argumenten ({loc}) maar moet er {int} hebben ({loc})',
						locsub(code, exp.loc),
						nargs, oorzaakloc[exp],
						N(tfn), oorzaakloc[tfn] or oorzaakloc[exp]
					)
					local a = fout2html(msg)
					if not fouten[a] then
						fouten[#fouten+1] = fout
						fouten[a] = true
					end
				end

				if N(tfn) ~= math.huge then
					if tfn.loc ~= nil then
						--print('PER STUK', moes(exp), loctekst(tfn.loc))
					end
					for i = 1, N(tfn) do
						--print(exp2string(exp[i]))
						--local arg = exp[i] or exp[1][i] or exp[1][1][i]
						local arg = ARG(exp, i)
						--print('N', N(tfn), exp2string(tfn))
						--if isfn(exp) and isfn(exp[1]) and exp[1].f.v == ',' then arg = exp[1][i] end
						if arg then
							assert(arg, i .. ', '..exp2string(exp))
							weestype(arg, A0(tfn, i), oorzaakloc[moes(exp.f)] or exp.f.loc)
						end
						--print('  ARG', moes(exp)i]), moes(A)tfn, i)), loctekst(exp[i].loc))
					end
				end
				if false then
					weestype(exp, tfn[2], oorzaakloc[moes(exp.f)] or exp.f.loc)
				end
				--print('  RET', moes(tfn)2]))

			end
		end
	end

	end -- for i=1,5

	-- is alles nu getypeerd?
	for exp in boompairs(exp) do
		if not types[exp] then
				if false and fn(exp) ~= '=' and fn(exp) ~= '=>' and fn(exp) ~= '[]' then
					local fout = typeerfout(exp.loc, 'kon type niet bepalen van {code}',
						combineer(exp)
					)
					local a = fout2string(fout)
					if not fouten[a] then
						fouten[#fouten+1] = fout
						fouten[a] = true
					end
			end
		end
	end

	local function isbieb(n)
		return n:match('bieb/.*')
	end

	local function rpijl2tekst(pijl)
		local r = {}
		for bron in pairs(pijl.van) do
			r[#r+1] = tostring(bron)
		end
		if #r == 0 then
			r[#r+1] = '()'
		end
		table.sort(r)
		return tostring(pijl.naar) .. ' <- ' .. table.concat(r, ' ')
	end

	if verbozeTypegraaf then
		print('=== TYPEGRAAF ===')
		local t = set2lijst(typegraaf.graaf.pijlen, function(a, b) return rpijl2tekst(a) < rpijl2tekst(b) end)
		for i,type in ipairs(t) do
			print(rpijl2tekst(type))
		end
		print()
	end

	if verbozeTypes then
		print()
	end

	return types, fouten
end

if test then
	-- automatisch verdiepen
	local tg = maaktypegraaf()
	tg:link(X'a', X'b')
	tg:link(X'b', X'c')

	tg:link(X'd', X'b')
end
