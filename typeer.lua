require 'exp'
require 'stroom'
require 'combineer'
require 'typegraaf'

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
local bieb,fouten = ontleed(bestand 'bieb/types.code')
if fouten then error('biebfouten') end

function typeer(exp)
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
		local type,super = X(v[1]),X(v[2])
		typegraaf:link(type, super)
		naamtypes[moes(type)] = super
		biebtypes[moes(type)] = super -- types: naam → type
	end

	local boom = exp
	local code = exp.code
	local bron = exp.bron or '?'

	-- verenigt types
	local function weestype(exp, type, typeoorzaakloc)
		local T,ol
		--print('wees type', moes(exp) .. ' : '..moes(type), typeoorzaakloc and loctekst(typeoorzaakloc))
		if types[exp] and moes(types[exp]) ~= moes(type) then
			local a = type
			local b = types[exp]

			-- type ⊂ T(exp)
			-- oftewel: b is specifieker
			if typegraaf:issubtype(b, a) then
				T = b or error('geen type')
			-- T(exp) ⊂ type
			-- oftewel: a is specifieker
			elseif typegraaf:issubtype(a, b) then
				T = a or error('geen type')
			elseif typegraaf:unie(a, b) then
				T = typegraaf:unie(a, b)
			else
				-- c.code@7:11-12: "a" is "int" maar moet "bit" zijn
				local isloc = oorzaakloc[exp] or exp.loc
				local moetloc = typeoorzaakloc or oorzaakloc[moes(exp)]
				local msg = string.format('%s@%s \t%s: %s is %s (%s) maar moet %s zijn (%s)',
					bron, loctekst(exp.loc), -- locatie
					color.red .. 'Typefout' .. color.white,
					color.brightyellow .. locsub(code, exp.loc) .. color.white, -- exp
					color.brightcyan .. combineer(types[exp]) .. color.white, -- echte type
					ansi.underline .. bron .. '@' .. loctekst(isloc) .. ansi.normal, -- echte type bron
					color.brightcyan .. combineer(type) .. color.white, -- moet zijn
					ansi.underline .. bron .. '@' .. loctekst(moetloc) .. ansi.normal -- moet zijn bron
				)
				-- kort: exp, istype, moettype
				--local kort = '%s is %s maar moet %s zijn'
				local fmt = '{exp} is {istype} maar moet {moettype} zijn'
				if not fouten[msg] then
					print(msg)
					fouten[#fouten+1] = {
						loc = exp.loc,
						msg = msg,
						fmt = fmt,
						exp = locsub(code, exp.loc),
						istype = combineer(types[exp]),
						moettype = combineer(type),
						isloc = isloc,
						moetloc = moetloc,
					}
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
		if T and not types[exp] or moes(types[exp]) ~= moes(T) then
			types[exp] = T
			naamtypes[moes(exp)] = T
			oorzaakloc[moes(exp)] = typeoorzaakloc or ol or exp.loc
			oorzaakloc[exp] = typeoorzaakloc or ol or exp.loc
			typegraaf:link(T)
			if verboos then
				local t = typeoorzaakloc or ol or exploc
				local s = t and '  vanwege ' .. (loctekst(t) or '')
				--print('TYPEER', moes(exp)..': '..moes(T))
			end
		end
	end

	-- eigen :)
	for i, exp in ipairs(exp) do
		if isfn(exp) and isatoom(exp.fn) and exp.fn.v == ':' then
			local val, type = exp[1],exp[2]
			weestype(val, type, exp.loc)
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
			--T = X'lijst'
			T = typegraaf.iets
			for i=1,#exp do
				local t = types[exp[i]]
				if not t then break end
				T = typegraaf:unie(T, t)
				if not T then break end
			end
			if T then T = {fn=X'lijst', T}
			else T = nil end
		elseif isfn(exp) and exp.fn.v == '{}' then
			T = X'set'
		elseif isfn(exp) and exp.fn.v == ',' then
			T = X'tupel'
		elseif biebtypes[moes(exp)] then
			T = biebtypes[moes(exp)] -- voorgedefinieerd is makkelijk
		end
		if T then
			if verboos then print('MAKKELIJK', moes(exp), moes(T))  end
			types[exp] = T
			typegraaf:link(T)
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

	for i=1,5 do

	-- rest van de types
	local T = {}
	for exp in boompairsdfs(exp, to) do
		if true or not types[exp] then

			local tfn = types[exp.fn]

			if #exp == 1 and isvar(exp.fn) and not types[exp.fn] and types[exp[1]] and types[exp] then
				-- typeer de functie zelf
				-- f(2) = 3 → f = getal → getal
				local functype = {fn=X'->', types[exp[1]], types[exp]}
				weestype(exp.fn, functype, exp.loc)
			end

			-- deze exp heeft al een type
			if naamtypes[moes(exp)] then
				local T = naamtypes[moes(exp)] -- voorgedefinieerd is makkelijk
				weestype(exp, T, oorzaakloc[moes(exp)])

			elseif isfn(exp) then
				local fn,f,a,b = exp.fn, exp.fn.v, exp[1], exp[2]

				-- speciaal voor '='
				if f == '=' then
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
							fouten[#fouten+1] = {loc = exp.loc, msg = msg}
							local msg = string.format('%s@%s: Typefout: links is %s (bron: %s), rechts is %s (bron: %s)',
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
		
				-- speciaal voor '⇒'
				elseif f == '=>' then
					weestype(a, X'bit', exp.fn.loc)
					if types[b] then weestype(exp, types[b], oorzaakloc[b]) end 

				-- speciaal voor ',' (tupel)
				-- ℝ × ℝ
				elseif f == ',' then
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
					-- argumenten
					--if isfn(fn) and fn.fn.v = ',' then
						--for 

					-- functie
					if naamtypes[moes(a)] and types[b] then
						weestype(a, naamtypes[moes(a)], oorzaakloc[moes(a)])
						weestype(b, types[b], oorzaakloc[b] or fn.loc)
						weestype(exp, X('->', naamtypes[moes(a)], types[b]), fn.loc)
					elseif types[a] and types[b] then
						weestype(exp, X('->', types[a], types[b])) ; oorzaakloc[exp] = exp.loc
					elseif types[b] then
						--weestype(exp, X('->', 'iets', types[b])) ; oorzaakloc[exp] = b.loc
					end
				end

			end

			if tfn and #tfn == 2 and tfn.fn.v == '->' then

				-- niet het gewenste aantal argumenten
				local nargs = #exp
				-- local unpacking
				if isfn(exp) and isfn(exp[1]) and exp[1].fn.v == ',' then nargs = #exp[1] end
				if N(tfn) ~= nargs and N(tfn) ~= math.huge then
					local msg = string.format('%s@%s: Typefout: "%s" heeft %d argumenten maar moet er %d hebben',
						bron, loctekst(exp.loc),
						locsub(code, exp.loc),
						nargs, N(tfn)
					)
					local kort = string.format('"%s" heeft %d argumenten maar moet er %d hebben',
						locsub(code, exp.loc), nargs, N(tfn)
					)
					if not fouten[msg] then
						print(msg)
						fouten[#fouten+1] = {loc = exp.loc, msg = msg, kort = kort}
						fouten[msg] = true
					end
				end

				if N(tfn) ~= math.huge then
					if tfn.loc ~= nil then
						--print('PER STUK', moes(exp), loctekst(tfn.loc))
					end
					for i = 1, N(tfn) do
						local arg = exp[i]
						if isfn(exp) and isfn(exp[1]) and exp[1].fn.v == ',' then arg = exp[1][i] end
						weestype(arg, A(tfn, i), exp.fn.loc)
						--print('  ARG', moes(exp)i]), moes(A)tfn, i)), loctekst(exp[i].loc))
					end
				end
				weestype(exp, tfn[2], exp.fn.loc)
				--print('  RET', moes(tfn)2]))

			end
		end
	end

	end

	if verboos then
		print()
		print('# Types')
		for exp, type in pairs(types) do
			print(moes(exp)..'\t: '..moes(type))
		end
		print()
	end

	--print(typegraaf.graaf:tekst())

	return types, fouten
end
