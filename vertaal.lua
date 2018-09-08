require 'util'
require 'lisp'

require 'ontleed'
require 'noem'
require 'sorteer'
require 'typeer'
require 'uitrol'
require 'voorwaartse_hypergraaf'
require 'ontrafel'

require 'js'

-- code in lisp formaat
function vertaalJs(lispcode)
	-- ontleed
	local feiten = lisp(lispcode)
	local waarden = noem(feiten)

	-- speel = bieb -> cirkels
	local invoer = {}
	local speel = {
		van = cat(invoer, bieb),
		naar = 'stip',
	}

	local stroom = sorteer(waarden, speel)
	local typen,fouten = typeer(stroom,basis)
	if fouten then
		print('ERROR')
	end
	local asmeta = uitrol(stroom, typen)
	local func = toJs(asmeta,typen)
	return func
end

function suikervrij(feiten)
	local r = {}
	for i,feit in ipairs(feiten) do
		if feit[1] == ':=' then
			local a,b = feit[2],feit[3]
			r[i] = {'=', a, {'=>', {'=', 'nu', 'start'}, b}}
		elseif feit[1] == '+=' then
			--		a += 1
			-- =>	a = (beeld => a' + 1 / 60)
			local a,b = feit[2],feit[3]
			local ao = {"'", a}
			local an = {'+', ao, {'/', b, '60'}}
			r[i] = {'=', a, {'=>', 'beeld', an}}
		else
			r[i] = feit
		end
	end
	return r
end

--[[
	a = (T < 5 => 2)
	a = (T > 5 => 3)
]]

--[[
vertaal = code -> stroom
	ontleed: code -> feiten
	typeer: feiten => (tak -> type)
	noem: feiten => (naam -> exp)
	sorteer: namen -> stroom

	typeer stroom
	uitrol: stroom -> makkelijke-stroom
]]
function vertaal(code)
	local feiten = ontleed(code)

	-- syntax
	if print_ingewanden then
		print('# Ontleed')
		print(unlisp(feiten))
		print()
	end

	-- stroef doen
	if #feiten == 0 then
		print(color.red..'geen geldige invoer gevonden'..color.white)
		return
	end

	-- bieb
	local bieb = ontleed(file('bieb.code'))
	local basis,fouten = typeer(bieb)
	if print_typen then print() end
	if fouten then
		for i,fout in ipairs(fouten) do print('BIEBFOUT',leed(fout)) end
	end

	-- typeer
	print_typen = print_typen_bron
	if print_typen then print('# Typen') end
	local typen,fouten = typeer(feiten,basis)
	if print_typen then print() end
	if fouten then return nil, fouten end

	-- syn suiker
	local feiten = suikervrij(feiten)

	if print_suikervrij then
		print('# Suikervrij')
		print(unlisp(feiten))
		print()
	end

	-- aggregeer verspreide waarden
	--local feiten = verzamel(feiten)

	-- extra info (vgl herschrijven)
	local feiten = deduceer(feiten)

	local afh,map = berekenbaarheid(feiten)
	local infostroom = afh:sorteer(bieb, 'stip')

	if print_infostroom then
		print('# Infostroom')
		print(infostroom:tekst())
		print()
	end

	-- terugmappen
	local stroom = {}
	for pijl,naar in infostroom:topologisch(map) do
		stroom[#stroom+1] = map[pijl]
	end

	-- makkelijker maken
	stroom = ontrafel(stroom)

	-- frisse avondbries
	print_typen = print_typen_stroom
	if print_typen then print('# Typen Stroom') end
	local typen = typeer(stroom,basis)
	if print_typen then print() end


	-- breid uit
	local stroom = uitrol(stroom, typen)

	if print_pseudocode then
		for i,ass in ipairs(stroom) do
			print(leed(ass))
		end
	end

	return stroom, typen
end
