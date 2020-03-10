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

-- code → struct
function vertaal(code, debug)
	local naam = naam or '?'
	local maakvar = maakvars()

	local asb,syntaxfouten,map = ontleed(code)
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

	local moes2naam = {}

	if debug then
		for naam, exp in pairs(varmap) do
			moes2naam[moes(exp)] = atoom(naam)
			print('revmap', atoom(naam), moes(exp))
		end
	end
		
	-- cachemap: exp → cacheindex
	local app,cachemap = codegen(exp, exp2naam)

	local naam2cache = {}
	for exp,index in pairs(cachemap) do
		print('cachemap', unlisp(exp), index)
		local naam = moes2naam[moes(exp)]
		if naam then
			naam2cache[naam] = index
			print('naam2cache', naam, index)
		end
	end
	
	-- varmap: {varnaam → cacheindex}
	return app, {}, naam2cache
end
