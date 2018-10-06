require 'util'
require 'lisp'

require 'ontleed'
require 'noem'
require 'sorteer'
require 'typeer'
require 'uitrol'
require 'voorwaartse-hypergraaf'
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

	-- stroef doen
	if #feiten == 0 then
		print(color.red..'geen geldige invoer gevonden'..color.white)
		return false
	end

	-- bieb
	local bieb = ontleed(file('bieb.code'))
	local basis,fouten = typeer(bieb)
	if print_typen then print() end
	if fouten then
		for i,fout in ipairs(fouten) do print('BIEBFOUT',leed(fout)) end
	end

	-- typeer
	local typen,fouten = typeer(feiten,basis)
	if fouten then return nil, fouten end

	-- syn suiker
	local feiten = suikervrij(feiten)

	-- herschrijf
	local feiten = deduceer(feiten)

	local afh,map = berekenbaarheid(feiten)
	local infostroom,fout = afh:sorteer('in', 'uit')
	if not infostroom then
		return false,fout
	end

	-- terugmappen
	local stroom = {}
	for pijl,naar in infostroom:topologisch(map) do
		stroom[#stroom+1] = map[pijl]
	end

	-- geen complexe feiten meer
	stroom = ontrafel(stroom)

	-- frisse avondbries
	local typen = typeer(stroom,basis)

	-- lussen uitrollen
	local stroom = uitrol(stroom, typen)

	return stroom, typen
end
