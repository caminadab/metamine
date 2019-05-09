require 'exp'
require 'util'
require 'graaf'
require 'symbool'
require 'combineer'

--[[
BLOK:
]]

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
	local cfg = graaf() -- blok
	local fns = {}
	local maakvar = maakvars()

	for sub in boompairsbfs(exp) do
		-- functies
		if isfn(sub) and isfn(sub.fn) then

			-- elke complexe functie moet _fn bevatten
			local func = sub.fn
			assert(fn(func) == '_fn')

			local argnum = atoom(func[1], 1)
			local waarde = func[2] or func[1][2] 

			-- verwijder args
			for subb in boompairsdfs(waarde) do
				if fn(subb) == '_arg' then
					subb.fn = nil
					subb.v = 'arg'
				end
			end

			-- we hebben maar 1 arg nodig nu
			local i = #fns
			fns[#fns+1] = waarde

			-- fix functieaanroep
			--func.fn = sym.call
			--func.fn = nil
			--func.v = 'fn'..i
			local fn = X('fn'..i)
			sub.fn = sym.call
			table.insert(sub, 1, fn)
		end

		-- als-dan logica
		if fn(sub) == '=>' then
			local cond, dan, anders = sub[1], sub[2], sub[3]

			-- dan
			local i = #fns
			fns[#fns+1] = dan
			sub[2] = X('fn' .. i)

			-- anders
			if anders then
				local i = #fns
				fns[#fns+1] = anders
				sub[3] = X('fn' .. i)
			end
		end
	end

	-- plet de start
	print('start:')
	local stats = plet(exp, maakvar)
	for i, stat in pairs(stats) do
		print('  '..combineer(stat))
	end
	print('  stop')

	-- plet de functies
	for i=1,#fns do
		local stats = plet(fns[i], maakvar)
		print('fn'..(i-1)..':')
		for i, stat in ipairs(stats) do
			print('  '..combineer(stat))
		end
		local ret = stats[#stats][1]
		print('  ret '..ret.v)
	end
end

if true or test then
	require 'lisp'
	require 'ontleed'
	local E = ontleedexp

	control(E'2 * 3 + 4')
	--control(E'_fn(0, _arg(0) + 1 · 3 ^ 2 + 8)')
	--control(E'_fn(0, _arg(0) ⇒ b · c + 3 / 7 ^ 3)')
end

