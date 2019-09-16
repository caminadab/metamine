require 'combineer'
require 'bieb'
require 'func'
require 'fout'

local function doeatoom(exp, env)
	if tonumber(exp.v) then
		return tonumber(exp.v)
	elseif env[exp.v] then
		return env[exp.v]
	elseif isobj(exp) then
		local t = {}
		for i,sub in ipairs(exp) do
			t[i] = doeatoom(sub, env)
		end
		return t
	else
		--error('onbekend: '..combineer(exp))
		return nil
	end
end

local function doestat(stat, env)
	assert(env)
	local cmd = stat.a[2]
	if isobj(cmd) then
		local o = obj(cmd)
		if true or o == ',' then
			local r = {}
			for i,v in ipairs(cmd) do
				r[i] = doeatoom(v, env)
			end
			return r
			--return map(cmd, doeatoom, env)
		end
	
	elseif isatoom(cmd) then
		return doeatoom(cmd, env)

	elseif isfn(cmd) then
		local fn = env[fn(cmd)]
		local arg = doeatoom(arg(cmd), env)
		--env['_arg'] = arg

		local ok, w = xpcall(fn, function(f) return f ..'\n' .. debug.traceback() end, arg)
		if not ok then
			local err = w
			local f = executiefout(stat.loc, err)
			print(fout2string(f))
			while true do
				io.write('> ')
				io.flush()
				local source = io.read('*l')
				if source == '' or source == '\x13' or source == 'exit' or source == 'quit' then
					break
				end
				local fn = load(source)
				env.print = function(a) print(combineer(w2exp(a))) end
				env._G = env
				setfenv(fn, env)
				local ok, msg = pcall(fn)
				if not ok then print(msg) end
			end
		end
		return w
	
	else
		error('wat is dit: '..combineer(stat))

	end
end

local function doestat0(stat, env)
	-- naam := exp
	-- naam := f(a,b)
	local naam,exp = stat.a[1],stat.a[2]
	local uit
	local w

	-- verkrijg waardes van argumenten enzo
	--exp = emap(exp, waarde, env, ...)

	--print(lenc(exp))
	--check(exp)

	if isatoom(exp) then
		if exp.v == '[]' then
			w = {}
		else
			w = exp.w
		end

	elseif exp.f and type(exp.f.w) == 'table' then
		-- woeps
		local a = exp.f.w
		local i = exp[1].w
		w = a[i+1]
		assert(w ~= nil, combineer(w2exp(a)) .. '.' .. combineer(w2exp(b)))

	elseif exp.f.v == '_fn' then
		w = env[fn(exp)]

	-- normale functie
	else
		local func = exp.f.w
		assert(func ~= nil, "geen functie voor "..e2s(exp.f))
		local args = {}
		for i,s in ipairs(exp) do
			args[i] = s.w
		end
		if type(func) == 'function' then
			--w = func(able.unpack(args))
			local ok
			ok, w = xpcall(func, function(f) return f ..'\n' .. debug.traceback() end, table.unpack(args))
			if not ok then
				local err = w
				local f = executiefout(stat.loc, err)
				print(fout2string(f))
				return
			end

		elseif type(func) == 'table' then
			w = func[args[1]]

		elseif type(func) == 'string' then
			w = func:sub(args[1]+1, args[1]+1)

		else
			print('ASDF', e2s(exp), exp.f.w, exp.w)
			local f = executiefout(stat.loc, 'onbekende "functie": '..tostring(func)..' : '..type(func)..' ('..combineer(stat)..')')
			print()
			print(fout2string(f))
		end

	end
	--assert(w ~= nil, 'Ontologiefout: '..combineer(exp) .. ' is niets')
	return w
end

-- doe een continu blok aan instructies
-- mogelijk met argumenten
local function doeblok(blok, env, arg)
	for i,stat in ipairs(blok.stats) do
		if opt and opt.L then
			-- locsub(exp.code, stat.loc), 
			io.write('  ', combineer(stat), '\t', loctekst(stat.loc), '\t\t' )
			io.flush()
		end

		local w = doestat(stat, env)

		if opt and opt.L then
			local exp = stat.a[2]
			local skip = fn(exp) == '_' and env[exp.a.v] == env.stduitSchrijf
			if not skip then
				io.write(combineer(w2exp(w)), '\n')
			end
		end

		env[stat.a[1].v] = w
	end
	local epi = blok.epiloog
	if fn(epi) == 'ret' then
		local a = env[blok.stats[#blok.stats].a[1].v]
		if opt and opt.L then print('ret '..tostring(a)) end
		return a
	elseif epi.v == 'stop' then
		local a =  env[blok.stats[#blok.stats].a[1].v]
		if opt and opt.L then print('stop') end
		return a
	elseif fn(epi) == 'ga' then
		local a,d,e = epi.a[1], epi.a[2], epi.a[3]
		if #epi.a == 3 then
			local b = env[a.v]
			local doel = b and d.v or e.v
			if opt and opt.L then print(string.format('ga %s want %s = %s', doel, a.v, b)) end
			assert(type(b) == 'boolean', 'sprongkeuze is niet binair: '..combineer(epi))
			return env[doel](arg)
		else
			if opt and opt.L then print('ga '..epi.a.v) end
			return env[epi.a.v](arg) -- sws jmp
		end
	else
		error('slechte epiloog: '..combineer(epi))
	end
end

function doejs(js)
	local jsnaam = os.tmpname()
	local resnaam = os.tmpname()
	file(jsnaam, js)
	os.execute(string.format('js %s > %s', jsnaam, resnaam))
	local res = file(resnaam):sub(1,-2)
	os.remove(jsnaam)
	os.remove(resnaam)
	return res
end

function doe(cfg)
	if cfg == nil then
		return nil
	end
	local bieb = bieb()
	assert(cfg.namen, 'is geen controlegraaf')
	local env = {}

	-- vul bieb
	for k,v in pairs(bieb) do
		env[k] = v
	end

	-- magie
	--env['als'] 

	for k,v in pairs(cfg.namen) do
		env[k] = function(arg)
			local isf = k:sub(1,2) == 'fn'
			if isf and opt and opt.L then print('...\ncall '..k..' '..combineer(w2exp(arg))) end
			env['_arg'] = arg
			local ret = doeblok(v, env, arg)
			if opt and opt.L then 
				--if isf then io.write('\n...') end
				----io.flush()
			end
			return ret
		end
	end



	-- GA
	local ret = doeblok(cfg.start, env)

	return ret
end
