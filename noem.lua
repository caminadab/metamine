require 'util'
require 'isoleer'
require 'symbool'
require 'voorwaartse_hypergraaf'

-- herschrijft vergelijkingen
-- herbruikt 'feiten'
function deduceer(feiten)
	local f = feiten
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
function berekenbaarheid(feiten)
	local hgraaf = hypergraaf()
	for i,feit in ipairs(feiten) do
		-- vergelijking?
		if isexp(feit) and feit[1] == '=' then
			local a,b = feit[2],feit[3]
			-- a = 1 + 2
			if isvar(a) then
				hgraaf:link(a, var(b))
			end
		
			-- 1 + 2 = b
			if isvar(b) then
				hgraaf:link(b, var(a))
			end
		end
	end
	return hgraaf
end

--assert(unlisp(noem(lisp'((= a 0) (= a 1))').a) == '(0 1)')
