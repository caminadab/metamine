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
			ins(tcs, X(':', exp, 'getal'))
			tcs[#tcs].code = exp.code
		end
		--ins(tcs, {exp=exp, type=exp, loc=exp.loc})
	elseif isobj(exp) then
		local o = obj(exp)
		if o == ',' then
			--ins(tcs, X(':', exp, 'tupel'))
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
				tcs[#tcs].code = exp.code
			end
			local fntype = std[fn(exp)]
			assert(fntype, 'onbekende standaardfunctie '..fn(exp))
			if fntype.a then
				ins(tcs, X(':', exp.a, fntype.a[1]))
				tcs[#tcs].code = exp.code
				ins(tcs, X(':', exp, fntype.a[2]))
				tcs[#tcs].code = exp.code
			end
		end
	end
	return tcs
end

local function opspoorRec(exp, tcs)
	local tcs = tcs or {}
	opspoor(exp, tcs)
	for k, sub in subs(exp) do
		opspoorRec(sub, tcs)
	end
	return tcs
end

-- verwerk constraints
function verwerk(cons, typegraaf, types, fouten)
	local ncons = {}
	for i, con in ipairs(cons) do
		if fn(con) == ':' then
			local exp,type = con.a[1], con.a[2]
			--local ok = typegraaf:link(type)
			local moettype = types[moes(exp)]

			if isobj(exp) and isobj(type) and obj(exp) == obj(type) then
				for i,sub in ipairs(exp) do
					ncons[#ncons+1] = X(':', sub, type[i])
				end
			end

			if moettype then
				if moes(moettype) ~= moes(type) then
					if typegraaf:issubtype(type, moettype) then
						ncons[#ncons+1] = X(':', moettype.bron, typen)
					elseif typegraaf:issubtype(moettype, type) then
						ncons[#ncons+1] = X(':', exp, moettype)

					else
						local fout = typeerfout(con.loc,
							"{code} is {exp} ({loc}) maar moet {exp} zijn ({loc})",
							locsub(con.code, con.loc),
							moettype, moettype.loc,
							type, type.loc
						)
						fouten[#fouten+1] = fout
					end
				end
			else
				if verbozeTypes then
					print('typeer', combineer(exp), combineer(type))
				end
				typegraaf:link(type)
				types[moes(exp)] = type
			end
		end
	end
	return ncons
end

function typeer(exp)
	-- exp...
	local moet = {exp}
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
	local prev = 1
	repeat
		--[[
		print()
		print('Ronde #'..ronde)
		print(#cons .. ' constraints')
		for i = 1, #cons do
			print("constraint", combineer(cons[i]))
		end
		]]

		cons,conflicten = verwerk(cons, typegraaf, types, fouten)
		--print(#cons..' over')
		ronde = ronde + 1
	until # cons == 0

	if #fouten > 0 then
		--print(typegraaf)
	end
	return types, fouten
end


if test then
	local a = ontleedexp('3')
	local ta = typeer(a)
	assert(ta:issubtype'getal')
end
