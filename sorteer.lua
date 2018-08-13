require 'func'
require 'graaf'
require 'noem' -- var()

local insert = table.insert
local remove = table.remove

-- gegeven een (benoemde) expressie
-- voeg simpele ops aan asm toe
-- zoals (+ 1 tijd0)
function unravelrec(exp,name,asm,g)
	local aname = name
	if g then aname = name .. g end
	local g = g or -1
	g = g + 1
	if atom(exp) then
		asm[#asm+1] = {':=', aname, exp}
	else
		-- subs
		local args = {}
		for i,sub in ipairs(exp) do
			if atom(sub) then
				args[i] = sub
			else
				args[i] = name..g
				g = unravelrec(sub,name,asm,g)
			end
		end
		-- zelf
		asm[#asm+1] = {':=', aname, args}
	end
	return g
end

-- [(= name exp)] -> [(= name0 fn)]
function ontrafel(flow)
	local asm = {}
	for i,v in ipairs(flow) do
		local name,exp = v[2],v[3]
		unravelrec(exp,name,asm)
	end

	local log = function()end
	log('# Unravel')
	for i,v in ipairs(asm) do
		log(v[2],'= '..unlisp(v[3]))
	end
	log()

	return asm
end

-- graaf = [punten, randen]
function sorteer(waarden, volgorde)
	local van, naar = volgorde.van, volgorde.naar
	local graaf = graaf()
	local oud = {}
	local nieuw = {naar}
	local klaar = {}
	local stroom = {}

	-- corrigeer invoer
	local van0 = {}
	if type(van) == 'table' then
		for k,v in ipairs(van) do
			van0[v] = true
		end
	else
		van0 = {[van] = true}
	end
	van = van0

	for naam in pairs(waarden) do graaf:voegtoe(naam) end
	for naam in pairs(van) do graaf:voegtoe(naam) end
	--for naam in pairs(naar) do graaf:voegtoe(naam) end

	while #nieuw > 0 do
		local naam = remove(nieuw, 1)
		local exps = waarden[naam]
		local foutegraaf
		assert(exps)

		-- link, dan testen of goed
		local ok
		local hoeken = {}
		for i,exp in ipairs(exps) do

			-- BEGIN CUSTOM
			if atom(exp) or exp[1] ~= '->' then
			-- END CUSTOM

			for bron in spairs(var(exp)) do
				-- als bron niet in de graaf zit
				-- dan laat hem van 'onbekend' afleiden
				if not waarden[bron] then
					print(color.red..bron .. ' is onbekend!'..color.white)
					waarden[bron] = {}
					hoeken[#hoeken+1] = {'onbekend',bron}
					graaf:voegtoe(bron)
					graaf:link('onbekend',bron)
					klaar[bron] = true
				end
				hoeken[#hoeken+1] = {bron,naam}
				graaf:link(bron,naam)
			end
			if not graaf:cyclisch() then
				ok = exp
				break
			else
				foutegraaf = graaf:tekst()
				for i,hoek in ipairs(hoeken) do
					graaf:ontlink(hoek[1], hoek[2])
				end
			end

			-- BEGIN STIEKEME SKIP
			else
				ok = exp
				break
			end
			-- END
		end

		-- goed
		if ok then
			stroom[#stroom+1] = {':=', naam, ok}
			
			-- BEGIN
			if not atom(ok) and ok[1] == '->' then
				ok = {}
			end
			-- EIND

			for naar in spairs(var(ok)) do
				if not klaar[naar] then
					nieuw[#nieuw+1] = naar
					klaar[naar] = true
				else
					-- ververs
					for i=1,#stroom do
						if stroom[i][2] == naar then
							local feit = stroom[i]
							local afh = remove(stroom, i)
							stroom[#stroom+1] = afh
							break
						end
					end
				end
			end

		-- constante
		elseif van[naam] then
			--print('GOED! constante')

		else
			if true then
				print(van[naam], 'OK', naam)
				print('geen oplossing voor '..unlisp(naam))
				print('foute graaf:')
				print(foutegraaf)
				print('---')
			end
			--[[
			print('mogelijkheden:')
			for i,exp in ipairs(exps) do
				print(naam..' = '..unlisp(exp))
			end
			print('graaf:')
			print(graaf:tekst())
			print('overtredende hoeken:')
			for i,hoek in ipairs(hoeken) do
				print(hoek[1]..' -> '..hoek[2])
			end
			error('afbreken.')
			]]
		end
	end

	local stroom = keerom(stroom)

	-- dubbelen
	local set = {}
	local r = {}
	for i=1,#stroom do
		if stroom[i] then
			local feit = stroom[i]
			local n,v = feit[2],feit[3]
			if not set[n] then
				r[#r+1]  = stroom[i]
			end
			set[n] = true
		end
	end

	local stroom = ontrafel(stroom)

	return stroom, {}
end

-- TESTS
if false then
	require 'lisp'

	local g = {a = {'b'}, b = {'a'}}
	local b = unlisp(sorteer(g, {naar='b',van='a'}))
	assert(b == '((= b a))', b)
	
	local code = [[
	(
		(= f (-> a a))
		(= x (f 0))
	)
	]]

	local a = noem(lisp(code))
	local b = unlisp(sorteer(a, {naar='x', van='f'}))
	assert(b == '((= f (-> a a)) (= x (f 0)))')
end
