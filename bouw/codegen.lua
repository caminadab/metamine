require 'exp'
require 'util'
require 'graaf'
require 'symbool'
require 'combineer'

require 'bouw.blok'

-- diepte bepalen
local function peil(waarde)
	-- bepaal diepte
	local diepte = {}

	for exp in boompairsdfs(waarde) do
		-- bladwaarden krijgen 1
		if isatoom(exp) then
			diepte[exp] = 1
		else
			diepte[exp] = 0
			local gelijk = false
			-- bepaal rec diepte
			for i,v in ipairs(exp) do
				if diepte[v] > diepte[exp] then gelijk = false
				elseif diepte[v] == diepte[exp] then gelijk = true
				end
				diepte[exp] = math.max(diepte[exp], diepte[v])
			end
			-- als ze zelfde zijn is er 1 extra nodig (voor phi?)
			if gelijk
				then diepte[exp] = diepte[exp] + 1
			end
		end
	end
	
	return diepte
end

local postop = set("%","!",".","'")
local binop  = set("+","·","/","^"," ","∨","∧","×","..","→","∘","_","‖","⇒",">","≥","=","≠","≈","≤","<",":=","+=","|:=", "∪","∩",":","∈")
local unop   = set("-","#","¬","Σ","|","%","√","!")

function codegen(exp, maakvar)
	local maakvar = maakvar or maakvars()
	local stats = {o=X","}
	local exp2naam = {}
	local moes2naam = {}
	local recycled = 0
	local totaal = 0

	for sub in boompairsdfs(exp) do
		-- bestaat al?
		if false and moes2naam[e2s(sub)] then
			recycled = recycled + 1
			totaal = totaal + 1
			exp2naam[sub] = moes2naam[e2s(sub)]
		else
			totaal = totaal + 1
			local gen = maakvar()

			local val
			if isfn(sub) then
				val = {f=sub.f}
				val.a = X((assert(exp2naam[sub.a], e2s(sub))))
			end
			if isobj(sub) then
				val = {o=sub.o}
				for k, sub in subs(sub) do
					val[k] = X((assert(exp2naam[sub], e2s(sub))))
				end
			end
			if isatoom(sub) then
				val = sub
			end
			local stat = X(":=", gen, val)
			exp2naam[sub] = gen
			moes2naam[e2s(sub)] = gen
			stats[#stats+1] = stat
		end
	end
	print(math.floor(recycled/totaal*100)..'% gerecycled')

	-- contract stats
	if true then
	for i=#stats-1,2,-1 do
		local x = stats[i+0]
		local y = stats[i+1]

		if isobj(arg1(x)) and isfn(arg1(y)) and isatoom(arg(arg1(y))) then
			arg1(y).a = x.a[2]
			table.remove(stats, i)
		end

		if false and isatoom(arg1(x)) and isfn(arg1(y)) then
			y.a[2].a = x.a[2]
			table.remove(stats, i)
		end

	end

	end

	return stats
end
