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

local prio = {
	['.'] = 9,
	['..'] = 8,
	['|'] = 8, -- a | 1 .. 2 komt zelden voor

	[':'] = 7,
	['as'] = 7,
	['is'] = 7,
	['to'] = 7,

	['^'] = 6,
	['_'] = 6,
	['*'] = 5,
	['/'] = 5,
	['%'] = 5,
	['+'] = 4,
	['-'] = 4,
	['+-'] = 4,

	['='] = 3,
	['!='] = 3,
	['~='] = 3,
	['>'] = 3,
	['<'] = 3,
	['>='] = 3,
	['<='] = 3,


	['@'] = 3,

	['and'] = 2,
	['or'] = 2,
	['xor'] = 2,
	['nor'] = 2,

	['=>'] = 1,
	['->'] = 1,
}

local tosas, toinfix

function toinfix(chunk)
	local fs = {}
	local vs = {}
	local s = {}
	-- functions
	for i,v in ipairs(chunk[1]) do
		push(vs, tosas(v[1]))
		push(fs, tosas(v[2]))
	end
	push(vs, tosas(chunk[2]))

	-- OP PREC
	-- 1 + 2 * 3
	local r = -99
	for i,f in ipairs(fs) do
		local v = vs[i]
		local p = prio[f]
		if p > r then
			push(s, {f,v})
			r = p
		elseif p == r and f == s[#s][1] then
			push(s[#s], v)
		else
			push(s[#s], v)
			r = prio[f]

			local l
			if #s > 1 then
				l = prio[s[#s-1][1]]
			else
				l = -99
			end

			while #s > 1 and p < l do
				--print('vouw', unlisp(s[#s-1]), unlisp(s[#s]))
				push(s[#s-1], s[#s])
				s[#s] = nil
				l = prio[s[#s][1]]
			end
			if true or p <= l then
				s[#s] = {f, s[#s]}
			else
				print(f)
			end
		end
	end

	-- fold
	push(s[#s], vs[#vs])
	while #s > 1 do
		push(s[#s-1], s[#s])
		s[#s] = nil
	end
	return s[1]
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
		return toinfix(chunk)

	elseif chunk.name == 'upre' then
		return { tosas(chunk[1]), tosas(chunk[2]) }

	elseif chunk.name == 'ubin' then
		return {
			tosas(chunk[2]),
			tosas(chunk[1]),
			tosas(chunk[3]),
		}

	elseif chunk.name == 'brackets' then
		return tosas(chunk[2])

	-- { true -> 3, false -> 2 }(a > b)
	elseif chunk.name == 'blockif' then
		local a = {'if', tosas(chunk[2]), tosas(chunk[3]) }
		-- elseif
		for i,v in ipairs(chunk[4]) do
		end
		-- else
		if chunk[5] ~= '' then
			a[4] = tosas(chunk[5][3])
		end
		return a

	elseif chunk.name == 'ruleif' then
		local a = {'if'}
		local block = tosas(chunk[2])
		block[1] = '&' -- het wordt een CONDISIE
		a[2] = block
		a[3] = tosas(chunk[5])
		return a

	elseif chunk.name == 'block' then
		local a = {'=>'}
		for i,v in ipairs(chunk[1]) do
			a[1+i] = tosas(v[3])
		end
		return a
	
	elseif chunk.name == 'blockfix' then
		local a = {}
		for i,v in ipairs(chunk[1]) do
			local op = v[3]
			if not a[1] then
				a[1] = op
			elseif a[1] and a[1] ~= op then
				error('BLOK-OPERATOR DISCREPANTIE')
			end
			a[1+i] = tosas(v[4])
		end
		return a

	elseif chunk.name == 'prefix' then
		local a = tosas(chunk[2])
		for i,v in ipairs(chunk[1]) do
			a = {v, a}
		end
		return a

	elseif chunk.name == 'list' then
		local r = tosas(chunk[2])
		local a = {'[]'}
		for i,v in ipairs(r) do
			a[1+i] = v
		end
		return a

	elseif chunk.name == 'set' then
		local r = tosas(chunk[2])
		local a = {'{}'}
		for i,v in ipairs(r) do
			a[1+i] = v
		end
		return a

	elseif chunk.name == 'collection' then
		local a = {}
		if chunk[1] ~= '' then
			a[1] = tosas(chunk[1])
		end
		for i,v in ipairs(chunk[2]) do
			a[1+#a] = tosas(v[2])
		end
		return a

	else
		error('onherkend: '..(chunk.name or '?'))
	end

end

function sas(src)
	local tokens = lex(src)
	local tokens = removecomments(tokens)
	local chunk = parse(fsas, tokens)
	if not chunk then
		print(unlisp(chunk))
		error('chunk fout')
	end
	local sas = tosas(chunk)
	return sas
end
