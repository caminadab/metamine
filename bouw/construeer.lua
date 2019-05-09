--[[
local taken = delta(uit)
local stroom = plan(taken)
local ssa = materialiseer(stroom)
local rtl = herbruik(ssa)
local asm = assembleer(rtl)
local elf = elf(asm)
]]

-- exp = co( uit ↦ 'H', net ↦ 'N' )
function delta(exp)
	assert(exp.fn.v == 'co')
	return X(sym.dan, 'start', exp)
end

require 'mmap'

local momenten = set("start", "stop", "na", "om", "leesbaar", "schrijfbaar", "gesloten", "fout")

function construeer(exp)
	local todo = delta(exp) -- ((( uitvoer --> data )))
	local stroom = plan(todo)
	for i, pijl in pairs(stroom:topologisch()) do
		print('PLAN', exp2string(pijl.naar))
	end
	do return todo end

	local ssa = materialiseer(stroom)
	--uit = ssa
	local rtl = herbruik(ssa)
	local mach = corrigeer(rtl) -- maak geschikt voor x64
	local asm = assembleer(mach)
	local elf = elf(asm)
	uit = exp2string(rtl)
	return uit
end


-- alles: vsync ⇒ update
function plan(alles)
	local h = stroom()
	local stop = sym.stop
	local update = alles[2]
	h:link(set(), update)
	h:link(update, stop)
	do return h end

	--do return X(sym.dan, 'vsync', alles) end
	local momenten = {start = {}, stop = {}}

	-- soort van typeer
	for iets in boompairsbfs(alles) do
		if isfn(iets) and iets.fn.v == "=>" and momenten[iets[1].v] or (isfn(iets[1]) and momenten[iets.fn.v]) then
			local moment = iets[1].v or iets[1][1].v
			local waarde = iets[2].v
			momenten[moment] = momenten[moment] or {}
			momenten[moment][waarde] = true
		end
	end

	local h = stroom()
	-- (uit = "hoi" na start + 3)
	if momenten.leesbaar or momenten.schrijfbaar or momenten.gesloten then
		h:pijl("start", "lus")
		h:pijl("lus", "stop")
	else
		h:pijl("start", "stop")
	end

	return h
end

function ssa(waarden)
	local t = {fn=X'SSA-BLOK'}
	for waarde in boompairsdfs(waarden) do
		print(waarde)
		-- a --> b
		t[#t+1] = waarde
	end
	return t
end

function materialiseer(plan)
	for pijl in pairs(plan:topologisch()) do
		ssa(pijl.naar)
	end
end
