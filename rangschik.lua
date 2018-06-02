require 'func'
require 'graaf'

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

-- [(:= name exp)] -> [(:= name0 fn)]
function ontrafel(flow)
	local asm = {}
	for i,v in ipairs(flow) do
		local name,exp = v[2],v[3]
		unravelrec(exp,name,asm)
	end

	local log = function()end
	log('# Unravel')
	for i,v in ipairs(asm) do
		log(v[2],':= '..unlisp(v[3]))
	end
	log()

	return asm
end

-- graaf = [punten, randen]
function rangschik(waarden,naar)
	local graaf = graaf()
	local oud = {}
	local nieuw = {naar}
	local klaar = {}
	local stroom = {}

	for naam in pairs(waarden) do
		graaf.punten[naam] = true
	end

	while #nieuw > 0 do
		local naam = remove(nieuw, 1)
		local exps = waarden[naam] or {}

		-- link, dan testen of goed
		local ok
		local hoeken = {}
		for i,exp in ipairs(exps) do
			for v in pairs(var(exp)) do
				if graaf.punten[v] and not graaf:bevat(v,naam) then
					hoeken[#hoeken+1] = {naam,v}
					graaf:link(naam,v)
				end
			end
			if not graaf:cyclisch() then
				print('ACYCLISCH',naam,unlisp(setlijst(var(exp))))
				ok = exp
				break
			else
				for i,hoek in ipairs(hoeken) do
					graaf:ontlink(hoek[1], hoek[2])
				end
			end
		end

		-- goed
		if ok then
			stroom[#stroom+1] = {':=', naam, ok}
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
		else
			print('Geen oplossing voor '..naam)
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

	--local stroom = ontrafel(stroom)

	return stroom, {}
end

