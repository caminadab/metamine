require 'typegraaf'
require 'ontleed'
require 'symbool'

local std = ontleed(file('bieb/std.code'), 'bieb/std.code')

function linkbieb(typegraaf)
	for i,feit in ipairs(std.a) do
		--print('FEIT', combineer(feit))
		if fn(feit) == ':' then
			local type, super = feit.a[1],feit.a[2]
			--print('LINK', combineer(type))
			typegraaf:link(type, super)
			std[moes(feit.a[1])] = super
			--typegraaf.types[moes(type)] = type
		end
	end
	return typegraaf
end

local typegraaf
function eztype(exp)
	if isatoom(exp) then
		if tonumber(exp.v) then
			if exp.v % 1 == 0 then
				return symbool.int
			else
				return symbool.getal
			end
		elseif std[exp.v] then
			return std[fn(exp)]
		end
	end

	if isobj(exp) then
		if obj(exp) == ',' then return symbool.tupel end
		if obj(exp) == '[]' then return symbool.lijst end
		if obj(exp) == '{}' then return symbool.set end
		if obj(exp) == '[]u' then return symbool.tekst end
	end

	-- functie
	if fn(exp) and std[fn(exp)] then
		return std[fn(exp)].a[2]
	end
end


function typeer(exp)
	local types = {}
	local todo = {} -- moes → exps...
	local permoes = permoes(exp)
	local fouten = {}

	typegraaf = maaktypegraaf()
	linkbieb(typegraaf)

	function weestype(exp, type)
		local moettype = types[exp]
		if types[moes(exp)] then
			-- oude
			local moet = types[moes(exp)]

			-- nieuwe info!
			if typegraaf:issubtype(type, moettype) then
				--todo[#todo+1] = X(':', exp, type)
			elseif typegraaf:issubtype(moettype, type) then
				-- voegt niets nieuws toe
				return
			else
				local fout = typeerfout(exp.loc,
					"{code} is {exp} maar moet {exp} zijn",
					bron(exp), moet, type
				)
				fouten[#fouten+1] = fout
			end
		end

		types[moes(exp)] = type
		print('typeer', combineer(exp), combineer(type))

		for i,alt in ipairs(permoes[moes(exp)]) do
			todo[#todo+1] = alt.super
			print('todo', combineer(todo[#todo]))
		end
	end

	function makkelijk(exp)
		function rec(exp)
			local type = eztype(exp)
			if type then
				weestype(exp, type)
			end
			for k,sub in subs(exp) do
				rec(sub)
			end
		end
		rec(exp)
	end
	makkelijk(exp)

	-- todo's
	for i,exp in ipairs(todo) do
		print('todo', combineer(exp))
		if fn(exp) == ',' and type(a) then
			error'OK'
		end
	end

	-- is alles getypeerd?
	for moes,exps in pairs(permoes) do
		if not types[moes] and not std[moes] and not typegraaf.types[moes] then
			local exp = exps[1]
			local fout = typeerfout(exp.loc or nergens,
				"kon type niet bepalen van {code}",
				isobj(exp) and combineer(exp) or locsub(exp.code, exp.loc)
			)
			fouten[#fouten+1] = fout
		end
	end


	return types, fouten
end
