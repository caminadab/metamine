require 'util'
require 'ontleed'
require 'typeer'
require 'bouw.arch'
require 'bouw.codegen'
require 'optimiseer'
require 'vertolk'
require 'oplos'
require 'vectoriseer'


function scope(x)
	local maakvar = maakvars()
	for exp in boompairs(x) do
		if fn(exp) == '→' then
			for naam in pairs(var(exp.a[1])) do
				local nnaam = X('scope'..maakvar()..'.'..naam.v)
				x.a = substitueer(x.a, naam, nnaam)
				--exp.a[2] = substitueer(exp.a[2], naam, nnaam)
			end
		end
	end
	return x
end

local diop2js = {
	['+'] = '+=',
	['·'] = '*=',
	['/'] = '/=',
}

local diops = {
	['>'] = '>',
	['≥'] = '>=',
	['='] = '==',
	['≤'] = '<=',
	['<'] = '<',
}

local function genjs(sfc)
	local focus = 1
	local gen = {}
	gen[#gen+1] = 'function main(A) {'
	for i,ins in ipairs(sfc) do
		if diop2js[atoom(ins)] then
			local a = varnaam(focus-2)
			local b = varnaam(focus-1)
			local op = diop2js[atoom(ins)]
			gen[#gen+1] = string.format('%s %s %s;', a, op, b)
			focus = focus - 1
		elseif diops[atoom(ins)] then
			gen[#gen+1] = string.format('var %s = %s %s %s;', varnaam(focus), atoom(ins), varnaam(focus-1))
		elseif fn(ins) == 'put' then
			gen[#gen+1] = string.format('var %s = %s;', varnaam(focus), atoom(arg(ins)))
		elseif fn(ins) == 'push' then
			focus = focus + 1
			gen[#gen+1] = string.format('var %s = %s;', varnaam(focus), atoom(arg(ins)))
		elseif atoom(ins) == 'dup' then
			gen[#gen+1] = string.format('var %s = %s;', varnaam(focus+1), varnaam(focus))
			focus = focus + 1
		elseif atoom(ins) == 'trip' then
			gen[#gen+1] = string.format('var %s = %s;', varnaam(focus+1), varnaam(focus))
			gen[#gen+1] = string.format('var %s = %s;', varnaam(focus+2), varnaam(focus))
			focus = focus + 2
		else
			gen[#gen+1] = '// '..combineer(ins)
		end
	end
	gen[#gen+1] = 'return A;'
	gen[#gen+1] = '}'
	return table.concat(gen, '\n')
end

-- code → struct
function vertaal(code, naam)
	local naam = naam or '?'
	local maakvar = maakvars()

	local asb,syntaxfouten,map = ontleed(code, naam)
	--local scoped = scope(asb)
	if type(asb) ~= 'table' then
		return nil, { syntaxfout(nergens, "rommel"); }
	end

	-- vertaal
	local asb = vertolk(asb)

	-- types
	local type,typeerfouten,types = typeer(asb)
	if #typeerfouten > 0 then
		return nil, cat(syntaxfouten, typeerfouten)
	end

	-- vectoriseer
	local asb = vectoriseer(asb, types)

	local exp,oplosfouten,varmap = oplos(asb, "main")
	
	if #oplosfouten > 0 then
		return nil, cat(syntaxfouten, typeerfouten, oplosfouten)
	end

	local revmap = {}
	for var, exp in pairs(varmap) do
		revmap[exp] = var
		--print('revmap', moes(exp), var)
	end
		
	-- cachemap: exp → cacheindex
	local app,cachemap = codegen(exp, revmap)

	local naam2cache = {}
	for exp,index in pairs(cachemap) do
		local naam = revmap[exp]
		if naam then
			naam2cache[naam] = index
			--print('naam2cache', naam, index)
		end
		--print('cachemap', unlisp(exp), index)
	end
	
	-- varmap: {varnaam → cacheindex}
	return app, {}, naam2cache
end
