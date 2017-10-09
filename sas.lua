require 'infix'

-- code = lijn^int
-- lijn = tabs || inhoud || '\n'
-- tabs = repeat '\t', i
function lijnen(code)
	local lijnen, info = {},{}
	local index = 0
	for lijn in code:gmatch('([^\n]*\n?)') do
		if #lijn == 0 then break end
		table.insert(lijnen, lijn)
		local comment
		if lijn:match('.*;.*') then
			lijn,comment = lijn:match('(.*)(;[\n]*)\n?')
		end
		local tabs,inhoud = lijn:match('(\t*)([^\n]*)\n?')
		local ilijn = {tabs=tabs,inhoud=inhoud, comment=comment, i=index}
		table.insert(info, ilijn)
		index = index + 1
	end
	return lijnen,info
end

function unmulti(exp, op)
	if atom(exp) or #exp < 2 then return exp end
	local res = {op,exp[1],exp[2]}
	for i=3,#exp do
		res = {op,res,exp[i]}
	end
	return res
end

-- (+ (+ 1 2) 3) -> (1 2 3)
function multi(sexp)
	local op = sexp[1]
	local m = {}
	while exp(sexp) and sexp[1] == op do
		table.insert(m, 1, sexp[3])
		sexp = sexp[2]
	end
	table.insert(m, 1, sexp)
	return m
end

function parse(code)
	local asb = {}
	local lijnen,info = lijnen(code)
	print("# LIJNEN", #lijnen)

	local boom = {}
	local stapel = {{}}

	function vouw(tot)
		for i=#stapel-1,tot,-1 do
			local sub = unmulti(stapel[i+1], 'and')
			sub[1] = '=>'
			stapel[i][#stapel[i]] = {'=',stapel[i][#stapel[i]], sub}
			--table.insert(stapel[i], sub)
			stapel[i+1] = nil
		end
	end

	for i,v in ipairs(lijnen) do
		local exp = infix(lex(v))
		if exp then
			local t = #info[i].tabs + 1
			vouw(t)
			stapel[t] = stapel[t] or {}
			table.insert(stapel[t], exp)
		end
	end

	vouw(1)
	local m = unmulti(stapel[1], 'and')
	m[1] = '=>'
	--print(unparseSexp(m))
	return m
end

function unparse(exp,tabs)
	local tabs = tabs or 0
	if not atom(exp) and exp[1] == '=>' and exp[2][1] == 'and' then
		print('ja')
		local res = {}
		local m = multi(exp[2])
		for i,v in ipairs(m) do
			print('V', unparseSexp(v))
			table.insert(res, string.rep('\t',tabs))
			table.insert(res, unparse(v, tabs+1))
			--table.insert(res, unparseInfix(v))
			table.insert(res, '\n')
		end
		print('R', unparseInfix(exp[3]))
		table.insert(res, unparseInfix(exp[3]))
		return table.concat(res)
	else
		return unparseInfix(exp)
	end
end



local ex = file('sas/decimal.sas')
local p = parse(ex)
print(unparse(p))
