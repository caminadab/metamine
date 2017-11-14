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
		local d = tokens[i-1]or''
		local good1 = a == '\n' and isindent(b) and not iswhite(c)
		local good2 = a == '\n' and not iswhite(b)
		local good3 = d == '\n' and isindent(a) and not iswhite(b)
		local good = good1 or good2 or good3
		if iswhite(a) and not good then
			table.remove(tokens, i)
		end
	end
	--print(unlisp(tokens))
	return tokens
end

function tosas(chunk)
	if atom(chunk) then
		return chunk
	
	elseif chunk.name == 'sas' then
		local s = {}
		s[1] = '=>'
		s[2] = tosas(chunk[2])
		for i,v in ipairs(chunk[3]) do
			s[2+i] = tosas(v[2])
		end
		return s
		
	-- [(1 +) (2 +)] 3
	elseif chunk.name == 'infix' then
		local a = { chunk[1][1][2] }
		a[2] = tosas(chunk[1][1][1])
		a[3] = tosas(chunk[2])
		return a

	elseif chunk.name == 'upre' then

	elseif chunk.name == 'ubin' then
		--

	elseif chunk.name == 'brackets' then
		return tosas(chunk[2])

	-- { true -> 3, false -> 2 }(a > b)
	elseif chunk.name == 'blockif' then
		local a = {'if', tosas(chunk[2]), tosas(chunk[3]) }
		-- elseif
		for i,v in ipairs(chunk[4]) do
		end
		return a

	elseif chunk.name == 'block' then
		local a = {'=>'}
		for i,v in ipairs(chunk[1]) do
			a[1+i] = tosas(v[3])
		end
		return a

	else
		error('onherkend: '..chunk.name)
	end

end

--local src = file('syntax.sas')
local src = [[
if a > 1
	b = 2
	c = 3
	d = 4
	e = 5
	f = 6
	g = 7
else
	x = 4
]]
local tokens = lex(src)
local tokens = removecomments(tokens)
local chunk = parse(fsas, tokens)

local sas = tosas(chunk)

print(unlisp(sas))
