require 'util'
require 'isoleer'
require 'symbool'
require 'voorwaartse_hypergraaf'

-- herschrijft vergelijkingen
-- herbruikt 'feiten'
function deduceer(feiten)
	local f = {}
	if print_deducties then print('# Deducties') end
	for i,feit in ipairs(feiten) do
		for naam in pairs(var(feit)) do
			local exp = isoleer(feit, naam)
			if exp then
				local dfeit = {'=', naam, exp}
				f[#f+1] = dfeit

				if print_deducties then
					print(leed(dfeit))
				end
			end
		end
	end
	if print_deducties then print() end
	return f
end

-- feiten -> AFHANKELIJKHEIDSHYPERGRAAF
-- plus: pijl -> feiten
function berekenbaarheid(feiten)
	local hgraaf = voorwaartse_hypergraaf()
	local map = {}

	for i,feit in ipairs(feiten) do
		-- vergelijking?
		if isexp(feit) and feit[1] == '=' then
			local a,b = feit[2],feit[3]
			-- a = 1 + 2
			if isvar(a) then
				local pijl = {van = var(b), naar = a}
				map[pijl] = feit
				hgraaf:link(pijl)
			end
		
			-- 1 + 2 = b
			if isvar(b) then
				local pijl = {van = var(a), naar = b}
				local feit = {feit[1],feit[3],feit[2]}
				map[pijl] = feit
				hgraaf:link(pijl)
			end

		end
	end
	return hgraaf, map
end

--assert(unlisp(noem(lisp'((= a 0) (= a 1))').a) == '(0 1)')
