require 'parse'

local fsas = ebnf(file('ebnf/sas.ebnf'))


require 'lisp'
--print(unebnf(fsas))

function iscomment(t) return t:sub(1,1) == ';' end
function iswhite(t) return t:match('%s*') == t end
function isindent(t) return t:match('\t*') == t end

-- simuleer een comment-remove fase
function removecomments(tokens)
	-- tokens weghalen
	for i=#tokens,1,-1 do
		local t = tokens[i]
		if iscomment(t) then
			table.remove(tokens, i)
		end
	end

	-- ruimte weghalen
	for i=#tokens,3,-1 do
		local a,b,c = tokens[i-2],tokens[i-1]or'',tokens[i]or''
		local good = iswhite(a) and isindent(b) and not iswhite(c)
		if iswhite(a) and not good then
			table.remove(tokens, i-2)
		end
	end
	return tokens
end

local src = file('syntax.sas')
--local src = '1 + -a * 3'
local tokens = lex(src)
local tokens = removecomments(tokens)
local chunk = parse(fsas, tokens)
print(unlisp(chunk))
