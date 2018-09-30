require 'util'
require 'lisp'

require 'ontleed'
require 'noem'
require 'sorteer'
require 'typeer'
require 'uitrol'
require 'voorwaartse_hypergraaf'
require 'ontrafel'
require 'plan'

require 'js'

function suikervrij(feiten)
	local r = {}
	for i,feit in ipairs(feiten) do

		-- start
		if feit[1] == ':=' then
			local a,b = feit[2],feit[3]
			r[i] = {'=', a, {'=>', 'start', b}}

		-- => omschrijffe
		elseif feit[1] == '=>' and isexp(feit[3]) and feit[3][1] == '=' then
			r[i] = {'=', feit[3][2], {'=>', feit[2], feit[3][3]}}

		-- inc
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

function constanten(exp,t)
	local t = t or {}
	if isexp(exp) then
		for i,v in ipairs(exp) do
			constanten(v,t)
		end
	else
		if tonumber(exp) then
			t[exp] = true
		end
	end
	return t
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
function vertaal(code, vt_doel)
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
	-- 1:19:00
	local feiten = deduceer(feiten)

	local bronnen = val(feiten)
	local afh,map = berekenbaarheid(feiten)
	--local van = union(basis,bronnen)
	local van = 'in'
	local infostroom = afh:sorteer(van, vt_doel)

	if print_infostroom then
		print('# Infostroom')
		print(infostroom:tekst())
		print()
	end

	-- terugmappen
	local stroom = {}
	for pijl,naar in infostroom:topologisch(map) do
		stroom[#stroom+1] = map[pijl]
		--print('PIJL',pijl2tekst(pijl), leed(map[pijl]))
	end

	-- makkelijker maken
	stroom = ontrafel(stroom)

	-- frisse avondbries
	print_typen = print_typen_stroom
	if print_typen then print('# Typen Stroom') end
	print('hhh',stroom,basis)
	local typen = typeer(stroom,basis)
	if print_typen then print() end


	-- breid uit
	local stroom = uitrol(stroom, typen)

	if print_pseudocode then
		print('# Pseudocode')
		for i,ass in ipairs(stroom) do
			print(leed(ass))
		end
		print()
	end

	-- lekker plannen
	local tijdstroom = plan(stroom)

	return stroom, typen
end
