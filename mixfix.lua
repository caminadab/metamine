require 'lex'

function peek(s,n)
	local n = n or 0
	return s[#s+n]
end

function sas(s)
	local a = stat(s)
end
-- {f = '+', [1] = 'a', [2] = 'b'}
function mixfix(tokens)
	return sas(tokens)
	

