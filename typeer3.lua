require 'util'
require 'ontleed'
require 'typegraaf'
require 'exp'
require 'fout'

local std = ontleed(file('bieb/std.code'), 'bieb/std.code')

function linkbieb(typegraaf)
	for i,feit in ipairs(std.a) do
		--print('FEIT', combineer(feit))
		if fn(feit) == ':' then
			local type, super = feit.a[1],feit.a[2]
			--print('LINK', combineer(type))
			typegraaf:link(type, super)
			std[moes(feit.a[1])] = super
			typegraaf.types[moes(type)] = type
		end
	end
	return typegraaf
end

local ins = table.insert

-- vind type constraints
local function opspoor(exp, tcs)
	-- atoomtype
	-- a = 3
	if isatoom(exp) then
		if tonumber(exp.v) then
			if exp.v % 1 == 0 then
				ins(tcs, X(':', exp, 'int'))
				tcs[#tcs].loc = exp.loc
			else
				ins(tcs, X(':', exp, 'getal'))
				tcs[#tcs].loc = exp.loc
			end
			tcs[#tcs].code = exp.code
		end
		if std[exp.v] and moes(exp) ~= moes(std[exp.v]) then
			ins(tcs, X(':', exp, std[exp.v]))
			tcs[#tcs].loc = exp.loc
		end
		--ins(tcs, {exp=exp, type=exp, loc=exp.loc})
	elseif isobj(exp) then
		local o = obj(exp)
		if o == ',' then
			local x = X(',', 'iets', 'iets')
			for i = 3,#o do
				x[#x+1] = X'iets'
			end
			ins(tcs, X(':', exp, x))
		elseif o == '[]' then
			ins(tcs, X(':', exp, 'lijst'))
		elseif o == '[]u' then
			ins(tcs, X(':', exp, 'tekst'))
		elseif o == '{}' then
			ins(tcs, X(':', exp, 'set'))
		end
		typeerExp(exp, 
		tcs[#tcs].code = exp.code
		tcs[#tcs].loc = exp.loc
	else
			-- uitzonderingen
			if fn(exp) == '=' then
				ins(tcs, exp)
				tcs[#tcs].loc = loc
			end

		if isfn(exp) then
			local fntype = fn(exp) == '_' and isatoom(exp.a[1]) and std[atoom(exp.a[1])]

			if fntype then

				if fntype.a then
					ins(tcs, X(':', exp.a[2], fntype.a[1]))
					tcs[#tcs].code = exp.code
					tcs[#tcs].loc = fntype.loc
					ins(tcs, X(':', exp, fntype.a[2]))
					tcs[#tcs].code = exp.code
					tcs[#tcs].loc = fntype.loc
					--ins(tcs, X(':', exp.f, fntype.f))
					--tcs[#tcs].code = exp.code
				end

			else

				fntype = fntype or std[fn(exp)]
				--assert(fntype, 'onbekende standaardfunctie '..fn(exp))
				if fntype and fntype.a then
					ins(tcs, X(':', exp.a, fntype.a[1]))
					tcs[#tcs].code = exp.code
					tcs[#tcs].loc = fntype.loc
					ins(tcs, X(':', exp, fntype.a[2]))
					tcs[#tcs].code = exp.code
					tcs[#tcs].loc = fntype.loc
				end

			end
		end
	end
	return tcs
end

local function opspoorRec(exp, tcs)
	local tcs = tcs or {}
	--print('exp '..exp.i..' = '..combineer(exp))
	opspoor(exp, tcs)
	for k, sub in subs(exp) do
		opspoorRec(sub, tcs)
	end
	return tcs
end

function typeerExp(exp, type, typegraaf, types, fouten, cons, permoes)
	--print('typeer', combineer(exp)..'#'..exp.i, ':', combineer(type))
	local moet = types[moes(exp)]

	if moet then

		if typegraaf:issubtype(moet, type) then
			type = moet

		elseif typegraaf:issubtype(type, moet) then
			--error'OK'
			--type = moet
			local moezen = permoes[moes(type)]
			if moezen then
				for k,exps in pairs(moezen) do
					for i,sub in ipairs(exps) do
						if sub ~= exp then
							cons[#cons+1] = X(':', sub, type)
							cons[#cons].loc = sub.loc
						end
					end
				end
			end

		else
			local fout = typeerfout(exp.loc,
				"{code} is {exp} maar moet {exp} zijn",
				locsub(exp.code, exp.loc),
				moet,
				type
			)
			--cons[#cons+1] = X(':', sub, 'fout')
			fouten[#fouten+1] = fout
		end
	
	end

	if verbozeTypes then
		print('typeer', combineer(exp)..' : '..combineer(type))
	end

	types[moes(exp)] = type
	types[exp] = type

	-- nichten
	for i, sub in ipairs(permoes[moes(exp)]) do
		if exp ~= sub and moes(type) ~= 'iets' and not types[moes(sub)] or types[sub] ~= type and moes(type) ~= 'iets' then
			cons[#cons+1] = X(':', sub, type)
			--print('SUB', sub.i, combineer(cons[#cons]))
		end
	end

	typegraaf:link(type)
end

-- pas constraints toe
function verwerk(cons, typegraaf, types, fouten, permoes)
	local ncons = {}
	for i, con in ipairs(cons) do

		if fn(con) == ':' then
			local exp,type = con.a[1], con.a[2]
			--local ok = typegraaf:link(type)
			local moettype = types[moes(exp)]

			-- tuple types
			if isobj(exp) and isobj(type) and obj(exp) == obj(type) then
				for i,sub in ipairs(exp) do
					if type[i] and moes(type[i]) ~= 'iets' then
						ncons[#ncons+1] = X(':', sub, type[i])
						ncons[#ncons].loc = sub.loc
					end
				end

			elseif moettype then
				if moes(moettype) ~= moes(type) then
				--print('MOET', combineer(moettype), combineer(type))
					if typegraaf:issubtype(type, moettype) then
						--cons[#ncons+1] = X(':', moettype.bron, typen)
						typeerExp(exp, type, typegraaf, types, fouten, ncons, permoes)
						-- TODO ripple

					elseif typegraaf:issubtype(moettype, type) then
						if moes(moettype) ~= moes(exp) then
							ncons[#ncons+1] = X(':', exp, moettype)
						end

					else
						local fout = typeerfout(exp.loc,
							"{code} is {exp} maar moet {exp} zijn",
							locsub(exp.code, exp.loc),
							type,
							moettype
						)
						fouten[#fouten+1] = fout
						--cons[#cons+1] = X(':', exp, 'fout')
					end
				else
				--typeerExp(exp, type, typegraaf, types, fouten, ncons, permoes)
				types[moes(exp)] = type
				end

			else
				--typegraaf:link(type)
				--types[exp = type
				typeerExp(exp, type, typegraaf, types, fouten, ncons, permoes)
			end

			-- effecten
			if fn(exp) == '∘' then
				local ta = types[exp.a[1]]
				local tb = types[exp.a[2]]
				if ta and tb and ta.a and tb.a and #ta.a == 2 and #tb.a == 2 then
					ncons[#ncons+1] = X('=', ta.a[2], tb.a[1])
					ncons[#ncons+1] = X(':', exp, X('→', ta.a[1], tb.a[2]))
				else
					ncons[#ncons+1] = con
				end
			end

			-- functies
			if fn(exp) == '→' and exp.a then
				local ta = types[exp.a[1]]
				local tb = types[exp.a[2]]
				--print('TA', combineer(types[exp.a]), combineer(tb))
				if types[exp.a] then
					ncons[#ncons+1] = X(':', exp, X('→', ta, tb))
					error'OK'
				else
					ncons[#ncons+1] = con
				end
			end

			-- touplesse
			if obj(exp) == ',' then
				local t = {o=X','}
				for i,v in ipairs(exp) do
					if types[moes(v)] then --and moes(types[v]) ~= 'iets' then
						t[i] = types[moes(v)]
					else
						--t = nil
						t[i] = X'iets'
					end
				end
				if t then
					ncons[#ncons+1] = X(':', exp, t)
				--	error'OK'
				else
					ncons[#ncons+1] = con
				end
			end

			-- (_): (A → B, A) → B
			if types[exp] and fn(exp) == '_' then
				local tfn = types[exp.a[1]] -- (A → B)
				local ta = types[exp.a[2]]
				if ta and tb and #arg(ta) == 2 then
					ncons[#ncons+1] = X(':', exp, arg(tfn)[2])
					ncons[#ncons+1] = X(':', arg(ta)[1], tb)
				end
			end

		-- type equaliteit
		elseif fn(con) == '=' then
			-- types moeten gelijk zijn?
			local a,b = con.a[1], con.a[2]
			local ta,tb = types[a], types[b]
					ncons[#ncons+1] = con

			if ta and tb then
				--print('TA & TB', combineer(ta), combineer(tb))
				if moes(ta) ~= moes(tb) then
					--typeerExp(b, ta, typegraaf, types, fouten, cons)

					if typegraaf:issubtype(ta, tb) then
						ncons[#ncons+1] = X(':', b, ta)
					elseif typegraaf:issubtype(tb, ta) then
						ncons[#ncons+1] = X(':', a, tb)
					else
						local fout = typeerfout(a.loc or nergens,
							"type mismatch: {code} : {exp} ≠ {code} : {exp}",
							locsub(a.code, a.loc), ta,
							locsub(b.code, b.loc), tb
						)
						fouten[#fouten+1] = fout
						--cons[#cons+1] = X(':', a, 'fout')
						--cons[#cons+1] = X(':', a, 'fout')
					end
						
					--[[local moettype = tb
					local type = ta
					]]
				end
			
			elseif ta then
				typeerExp(b, ta, typegraaf, types, fouten, ncons, permoes)

			elseif tb then
				typeerExp(a, tb, typegraaf, types, fouten, ncons, permoes)

			else

			end
			
		end
	end
	return ncons
end

function permoesR(exp, moezen)
	local m = moes(exp)
	moezen[m] = moezen[m] or {}
	moezen[m][#moezen[m]+1] = exp
	for k,sub in subs(exp) do
		permoesR(sub, moezen)
	end
end

function permoes(exp)
	local moezen = {}
	permoesR(exp,  moezen)
	return moezen
end

function typeer(exp)
	-- exp...
	local regels = {}
	local fouten = {}
	local types = {}

	-- type constraint:
	-- {exp, type, in={types}}

	-- tg
	local typegraaf = linkbieb(maaktypegraaf())

	-- rondgaan
	local ronde = 1
	local conflicten = {}

	local cons = opspoorRec(exp, tcs)
	-- moes → exp
	local permoes = permoes(exp)
	local prev = 1
	types[moes(exp)] = X'⊤'
	repeat
		print()
		print('Ronde #'..ronde)
		print(#cons .. ' constraints')
		for i = 1, #cons do
			print("constraint", combineer(cons[i]))--, cons[i].loc and loctekst(cons[i].loc))
		end

		cons,conflicten = verwerk(cons, typegraaf, types, fouten, permoes)
		--print(#cons..' over')
		ronde = ronde + 1
	until # cons == 0 or ronde > 5

	-- check
	-- kijk of ze alleen getypeerd zijn
	for moes,exps in pairs(permoes) do
		if not types[moes] and not typegraaf.types[moes] then
			local exp = exps[1]
			local fout = typeerfout(exp.loc or nergens,
				"kon type niet bepalen van {code} ",
					locsub(exp.code, exp.loc)
			)
			fouten[#fouten+1] = fout
		end
	end

	return types, fouten
end
symbool = sym


if test then
	local a = ontleedexp('3')
	local ta = typeer(a)
	assert(ta:issubtype'getal')
end
