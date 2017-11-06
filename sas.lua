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
	for i=#tokens,1,-1 do
		local a,b,c = tokens[i]or'',tokens[i+1]or'',tokens[i+2]or''
		local good1 = a == '\n' and isindent(b) and not iswhite(c)
		local good2 = a == '\n' and not iswhite(b)
		local good3 = isindent(a) and not iswhite(b)
		local good = good1 or good2 or good3
		if iswhite(a) and not good then
			if tokens[i] == '\t' and i < 10 then
				print('remove TABS', i)
				print(good1, good2)
			end
			table.remove(tokens, i)
		end
	end
	--print(unlisp(tokens))
	return tokens
end

local src = file('syntax.sas')
--local src = '1 + -a * 3'
local tokens = lex(src)
local tokens = removecomments(tokens)
--for i=1,10 do print(escape(tokens[i])) end
local chunk = parse(fsas, tokens)
print(unlisp(chunk))
