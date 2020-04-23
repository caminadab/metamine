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
function vertaal(code, isdebug)
	local naam = naam or '?'
	local maakvar = maakvars()

	local prev = socket.gettime()
	local asb,syntaxfouten,map = ontleed(code)
	--local scoped = scope(asb)
	if type(asb) ~= 'table' then
		return nil, { syntaxfout(nergens, "rommel"); }
	end
	local delta = socket.gettime() - prev
	local ms = math.floor(delta * 1000)
	if debugprint then
		print('ontleed\t' ..ms..' ms')
	end
	local prev = socket.gettime()

	-- vertaal
	local asb = vertolk(asb)

	-- types
	local type,typeerfouten,types = typeer(asb)
	if #typeerfouten > 0 then
		return nil, cat(syntaxfouten, typeerfouten)
	end

	local delta = socket.gettime() - prev
	local ms = math.floor(delta * 1000)
	if debugprint then
		print('typeer\t' ..ms..' ms')
	end
	local prev = socket.gettime()

	-- vectoriseer
	local asb = vectoriseer(asb, types)

	check(asb)

	local exp,oplosfouten,varmap = oplos(asb, "main", isdebug)
	
	local delta = socket.gettime() - prev
	local ms = math.floor(delta * 1000)
	if debugprint then
		print('oplos\t' ..ms..' ms')
	end
	local prev = socket.gettime()

	if #oplosfouten > 0 then
		return nil, cat(syntaxfouten, typeerfouten, oplosfouten)
	end

	-- optimiseer
	if not isdebug and (not opt or not opt['0']) then
		exp = optimiseer(exp)

		local delta = socket.gettime() - prev
		local ms = math.floor(delta * 1000)
		if debugprint then
			print('optimiseer\t' ..ms..' ms')
		end
		local prev = socket.gettime()
	end

	-- opgelost
	if verbozeWaarde then
		print('=== WAARDE ===')
		print(unlisp(exp))
		print()
	end


	local moes2naam = {}

	if isdebug then
		for naam, exp in pairs(varmap) do
			moes2naam[moes(exp)] = atoom(naam)
			--print('revmap', atoom(naam), moes(exp))
		end
	end
		
	-- cachemap: exp → cacheindex
	local app,cachemap = codegen(exp, moes2naam)

	local delta = socket.gettime() - prev
	local ms = math.floor(delta * 1000)
	if debugprint then
		print('codegen\t' ..ms..' ms')
	end
	local prev = socket.gettime()

	local naam2cache = {}
	for exp,index in pairs(cachemap) do
		--print('cachemap', unlisp(exp), index)
		local naam = moes2naam[moes(exp)]
		if naam then
			naam2cache[naam] = index
			--print('naam2cache', naam, index)
		end
	end
	
	-- varmap: {varnaam → cacheindex}
	return app, {}, naam2cache
end
