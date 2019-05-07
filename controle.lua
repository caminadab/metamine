require 'exp'
require 'util'

-- plet tot een fijne moes
-- dit bevat alleen atomaire functies, die tellen niet mee voor de (((factor)))
local function plet(waarde, maakvar)
	--for exp in boompairs(waarde) do assert(not isfn(exp) or isatoom(exp.fn)) end

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

	local vars = {} -- exp2vars
	local stats = {}

	local function r(exp)
		--if isatoom(exp) then return end
		-- diepste tak eerst
		if diepte[exp] == 0 and false then
			return
		else
			-- sorteer op diepte
			local args = {}
			for i,v in ipairs(exp) do
				args[i] = v
			end
			table.sort(args, function (a, b) return diepte[a] < diepte[b] end)

			for i,v in ipairs(args) do
				-- alleen expressiekinderen hoeven berekend te worden
				if isexp(v) then
					r(args[i])
				end
			end

			-- nu al onze kinderen geweest zijn kunnen wij
			for i,v in ipairs(exp) do
				exp[i] = vars[v] or exp[i]
			end

			local var = maakvar()
			vars[exp] = X(var)
			stats[#stats+1] = X(sym.ass, var, exp)
		end
	end

	r(waarde)

	return stats
end

-- control flow graph builder
function control(exp)
	local fns = {}
	local maakvar = maakvars()
	assert(maakvar)

	for sub in boompairsdfs(exp) do
		-- functies
		if fn(sub) == '_fn' then
			local argnum = atoom(sub[1], 1)
			local waarde = sub[2] or sub[1][2] 

			-- verwijder arg
			for subb in boompairsdfs(waarde) do
				if fn(subb) == '_arg' then
					subb.fn = nil
					subb.v = 'arg'
				end
			end

			-- we hebben maar 1 arg nodig nu
			fns[#fns+1] = waarde

			-- fix deze
			sub.fn = nil
			sub.v = 'fn'..#fns
		end

		-- als-dan logica
		if fn(sub) == '=>' then
			local cond, dan = sub[1], sub[2]
			fns[#fns+1] = cond
			fns[#fns+1] = dan
			sub[2] = X('fn' .. #fns+1)
		end
	end

	-- de exp kan in zijn geheel worden geplet: alle onveilige rommel is eruit
	fns[#fns+1] = exp

	-- plet de functies
	for i,fn in ipairs(fns) do
		local stats = plet(fn, maakvar)
		print('fn'..(i-1)..':')
		for i, stat in pairs(stats) do
			print('  '..combineer(stat))
		end

	end
end

if test then
	require 'lisp'
	local E = ontleedexp

	control(E'_fn(0, _arg(0) + 1 · 3 ^ 2 + 8)')
	control(E'_fn(0, _arg(0) ⇒ b · c + 3 / 7 ^ 3)')
end

