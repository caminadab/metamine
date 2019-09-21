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
			else
				ins(tcs, X(':', exp, 'getal'))
			end
			tcs[#tcs].code = exp.code
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
			tcs[#tcs].code = exp.code
		elseif o == '[]' then
			ins(tcs, X(':', exp, 'lijst'))
			tcs[#tcs].code = exp.code
		elseif o == '[]u' then
			ins(tcs, X(':', exp, 'tekst'))
			tcs[#tcs].code = exp.code
		elseif o == '{}' then
			ins(tcs, X(':', exp, 'set'))
			tcs[#tcs].code = exp.code
		end
	else
		if isfn(exp) then
			-- uitzonderingen
			if fn(exp) == '=' then
				ins(tcs, exp)
			end
			local fntype = fn(exp) == '_' and isatoom(exp.a[1]) and std[atoom(exp.a[1])]

			if fntype then

				--print('FNTYPE', fntype and combineer(fntype))

				if fntype.a then
					ins(tcs, X(':', exp.a[2], fntype.a[1]))
					tcs[#tcs].code = exp.code
					ins(tcs, X(':', exp, fntype.a[2]))
					tcs[#tcs].code = exp.code
					--ins(tcs, X(':', exp.f, fntype.f))
					--tcs[#tcs].code = exp.code
				end

			else

				fntype = fntype or std[fn(exp)]
				assert(fntype, 'onbekende standaardfunctie '..fn(exp))
				if fntype.a then
					ins(tcs, X(':', exp.a, fntype.a[1]))
					tcs[#tcs].code = exp.code
					ins(tcs, X(':', exp, fntype.a[2]))
					tcs[#tcs].code = exp.code
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
			fouten[#fouten+1] = fout
		end
	
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
					end
				end
			end

			if moettype then
				if moes(moettype) ~= moes(type) then
				--print('MOET', combineer(moettype), combineer(type))
					if typegraaf:issubtype(type, moettype) then
						--ncons[#ncons+1] = X(':', moettype.bron, typen)
						typeerExp(exp, type, typegraaf, types, fouten, ncons, permoes)
					elseif typegraaf:issubtype(moettype, type) then
						ncons[#ncons+1] = X(':', exp, moettype)

					else
						local fout = typeerfout(exp.loc,
							"{code} is {exp} maar moet {exp} zijn",
							locsub(exp.code, exp.loc),
							type,
							moettype
						)
						fouten[#fouten+1] = fout
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
		
		-- type equaliteit
		elseif fn(con) == '=' then
			-- types moeten gelijk zijn?
			local a,b = con.a[1], con.a[2]
			local ta,tb = types[moes(a)], types[moes(b)]

			if ta and tb then
				--print('TA & TB', combineer(ta), combineer(b))
				if moes(ta) ~= moes(tb) then
					--typeerExp(b, ta, typegraaf, types, fouten, cons)
					cons[#cons+1] = X(':', b, ta)
					cons[#cons+1] = X(':', a, tb)
						
					--[[local moettype = tb
					local type = ta
					]]
				end
			
			elseif ta then
				typeerExp(b, ta, typegraaf, types, fouten, ncons, permoes)

			elseif tb then
				typeerExp(a, tb, typegraaf, types, fouten, ncons, permoes)

			else
				ncons[#ncons+1] = con

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
		--[[
		print()
		print('Ronde #'..ronde)
		print(#cons .. ' constraints')
		for i = 1, #cons do
			print("constraint", combineer(cons[i]))
		end
		]]

		cons,conflicten = verwerk(cons, typegraaf, types, fouten, permoes)
		--print(#cons..' over')
		ronde = ronde + 1
	until # cons == 0 or ronde > 5

	-- check
	-- kijk of ze alleen getypeerd zijn
	for moes,exps in pairs(permoes) do
		if false and not types[moes] and not typegraaf.types[moes] then
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


if test then
	local a = ontleedexp('3')
	local ta = typeer(a)
	assert(ta:issubtype'getal')
end
