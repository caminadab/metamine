require 'util'
require 'parse'
require 'typify'
require 'build.codegen'
require 'optimise'
require 'translate'
require 'solve'
require 'vectorise'


local function vars(exp)
	local t = {}
	local function vars(exp)
		if isatom(exp) then
			if not tonumber(atom(exp)) then
				t[#t+1] = exp
			end
		else
			for k, sub in subs(exp) do
				vars(sub)
			end
		end
	end
	vars(exp)
	return t
end

local function scope2(x)
	local makevar = makevars()
	for exp in treepairs(x) do
		if fn(exp) == '→' then
			for name in pairs(var(exp.a[1])) do
				local nname = X('scope'..makevar()..'.'..name.v)
				x.a = substitute(x.a, name, nname)
				--exp.a[2] = substitute(exp.a[2], name, nname)
			end
		end
	end
	return x
end

local function scope(exp)
	local makescope = makevars()
	for exp in treepairs(exp) do
		if fn(exp) == '→' then
			local body = arg1(exp)
			local scope = makescope()..'_'
			local vars = vars(arg0(exp))

			for i,var in ipairs(vars) do
				local varname = atom(var)
				local letter = varname:sub(1,1)
				if string.upper(letter) == letter then
					local newname = X(scope .. varname)
					assign(var, newname)

					for exp in treepairsdfs(body) do
						if atom(exp) == varname then
							assign(exp, newname)
						end
					end
				end
			end

		end
	end
	return exp
end


-- code → struct
function compile(code, isdebug)
	local name = name or '?'
	local makevar = makevars()
	local opt = opt or {}

	local prev = nu()
	local asb,syntaxerroren,map = parse(code)
	local asb = scope(asb)

	if type(asb) ~= 'table' then
		return nil, { syntaxerror(nergens, "rommel"); }
	end
	local delta = nu() - prev
	local ms = math.floor(delta * 1000)
	if opt.D then
		print('parse\t' ..ms..' ms')
	end
	local prev = nu()

	-- compile
	local asb = translate(asb)

	-- types
	local type,typeerrors,types = typify(asb)
	if #typeerrors > 0 then
		return nil, cat(syntaxerroren, typeerrors)
	end

	local delta = nu() - prev
	local ms = math.floor(delta * 1000)
	if opt.D then
		print('typify\t' ..ms..' ms')
	end
	local prev = nu()



	check(asb)

	local asb = vectorise(asb, types, isdebug)


	local exp,solveerrors,varmap = solve(asb, "main", isdebug)

	-- vectorise
--	local exp = vectorise(exp, types, isdebug)

	
	local delta = nu() - prev
	local ms = math.floor(delta * 1000)
	if opt.D then
		print('solve\t' ..ms..' ms')
	end
	local prev = nu()

	if #solveerrors > 0 then
		return nil, cat(syntaxerroren, typeerrors, solveerrors)
	end

	-- optimise
	if not isdebug and (not opt or not opt['0']) then
		-- opgelost
		if verbozeWaarde then
			print('=== ORIGINELE WAARDE ===')
			print(unlisp(exp))
			print()
		end

		exp = optimise(exp)

		local delta = nu() - prev
		local ms = math.floor(delta * 1000)
		if opt.D then
			print('optimise\t' ..ms..' ms')
		end
		local prev = nu()

	else
		exp = refunc(exp)

	end

	-- opgelost
	if verbozeWaarde then
		print('=== WAARDE ===')
		print(unlisp(exp))
		print()
	end


	local hash2name = {}

	if isdebug then
		for name, exp in pairs(varmap) do
			hash2name[hash(exp)] = atom(name)
			--print('revmap', atom(name), hash(exp))
		end
	end
		
	-- cachemap: exp → cacheindex
	local app,cachemap = codegen(exp, hash2name)

	local delta = nu() - prev
	local ms = math.floor(delta * 1000)
	if opt.D then
		print('codegen\t' ..ms..' ms')
	end
	local prev = nu()

	local name2cache = {}
	for exp,index in pairs(cachemap) do
		--print('cachemap', exp, index)
		local name = hash2name[exp]
		if name then
			name2cache[name] = index
			--print('name2cache', name, index)
		end
	end
	
	-- varmap: {varname → cacheindex}
	return app, {}, name2cache
end
