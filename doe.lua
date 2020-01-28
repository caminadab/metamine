require 'combineer'
require 'bieb'
require 'func'
require 'fout'

local function doeatoom(exp, env)
	if tonumber(exp.v) then
		return tonumber(exp.v)
	elseif env[exp.v] ~= nil then
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

		local ok, res = pcall(fn, arg)
		if not ok then
			local err = res
			local fout = executiefout(stat.loc, '{code}: '..err:match('([^\n]+)'), bron(stat))
			if opt and opt.L then print('...') end
			print(fout2ansi(fout))
			while false do
				io.write('> ')
				io.flush()
				local source = io.read('*l')

				if source == '' or source == '\x13' or source == 'exit' or source == 'quit' then
					break
				end
				local fn = load(source)
				env.print = function(a) print(lenc(a)) end
				env._G = env
				setfenv(fn, env)
				local ok, msg = pcall(fn)
				if not ok then print(msg) end
			end
			return fout
		end
		return res
	
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
		assert(w ~= nil, lenc(a) .. '.' .. lenc(b))

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
				--print(fout2string(f))
				w = nil
				return
			end

		elseif type(func) == 'table' then
			w = func[args[1]]

		elseif type(func) == 'string' then
			w = func:sub(args[1]+1, args[1]+1)

		else
			w = nil
			print('ASDF', e2s(exp), exp.f.w, exp.w)
			local f = executiefout(stat.loc, 'onbekende "functie": '..tostring(func)..' : '..type(func)..' ('..combineer(stat)..')')
			print()
			print(fout2ansi(f))
		end

	end
	--assert(w ~= nil, 'Ontologiefout: '..combineer(exp) .. ' is niets')
	return w
end

-- doe een continu blok aan instructies
-- mogelijk met argumenten
local function doeblok(blok, env, arg)
	assert(blok, 'geen blok!')
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
				io.write(lenc(w), '\n')
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
			assert(type(b) == 'boolean', 'sprongkeuze is niet binair: '..combineer(epi)..', cond='..tostring(b))
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

function doe(app)
	if app == nil then
		return nil
	end
	local bieb = bieb()
	local env = {}

	-- vul bieb
	for k,v in pairs(bieb) do
		env[k] = v
	end

	for naam,blok in pairs(app) do
		env[naam] = function(arg)
			local isf = naam:sub(1,2) == 'fn'
			if opt and opt.L then print('...\ncall '..naam..' '..lenc(arg)) end
			env['_arg'] = arg
			local ret = doeblok(blok, env, arg)
			if opt and opt.L then 
				if isf then io.write('\n...') end
				io.flush()
			end
			return ret
		end
	end

	-- GA
	local socket = require 'socket'
	local ret

	-- init
	local starttijd = socket.gettime()
	env.looptijd = 0
	doeblok(app.init, env)

	while true do
		io.write(ansi.wisregel, ansi.regelbegin)
		ret = doeblok(app.init, env)
		env.looptijd = socket.gettime() - starttijd
		socket.sleep(1/10)
	end

	return ret
end
