require 'util'
require 'isoleer'
require 'symbool'

-- feiten -> (naam -> exp)
function noem(feiten)
	local r = {}
	for i,feit in ipairs(feiten) do
		for naam in spairs(var(feit)) do
			local exp = isoleer(feit, naam)
			if exp then
				r[naam] = r[naam] or {}
				r[naam][#r[naam]+1] = exp

				if print_losse_waarden then
					print(naam..' = '..unlisp(exp))
				end
			else
				--print('kon niet oplossen voor '..naam)
			end
		end
	end
	return r
end

assert(unlisp(noem(lisp'((= a 0) (= a 1))').a) == '(0 1)')
