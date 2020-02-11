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

-- exp → sfc
function codegen(exp)
	local ins = {}
	local stack = {1}
end

function codegen2(exp, maakvar)
	local maakvar = maakvar or maakvars()
	local stats = X(",")
	local klaar = {}

	for sub in boompairsdfs(exp) do
		-- bestaat al?
		if not klaar[sub] then
			local gen = maakvar()

			local val
			if isfn(sub) then
				val = {f=sub.f}
				val.a = X((assert(klaar[sub.a], e2s(sub))))
			end
			if isobj(sub) then
				val = {o=sub.o}
				for k, sub in subs(sub) do
					val[k] = X((assert(klaar[sub], e2s(sub))))
				end
			end
			if isatoom(sub) then
				val = sub
			end
			local stat = X(":=", gen, val)
			klaar[sub] = gen
			stats[#stats+1] = stat
		end
	end

	-- contract stats
	if false then
		for i=#stats-1,2,-1 do
			local x = stats[i+0]
			local y = stats[i+1]

			local v, w = arg1(x), arg1(y)

			if isobj(arg1(x))
					and obj(v) == ','
					and isfn(w)
					and isatoom(arg(w)) then
				v.a = w
				--table.remove(stats, i)
			end

			if false and isatoom(arg1(x)) and isfn(arg1(y)) then
				y.a[2].a = x.a[2]
				table.remove(stats, i)
			end

		end
	end

	return stats
end
