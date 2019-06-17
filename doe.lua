require 'combineer'
require 'bieb'
require 'func'
require 'fout'

local function waarde(a, env)
	if isatoom(a) then
		local w = tonumber(a.v) or env[a.v] or (a.v == '_arg' and "JA")
		if w == nil then 
			error('onbekend: '..tostring(a.v))
		end
		a.w = w
	end
	return a
end

local function doeblok(blok, env, ...)
	for i,stat in ipairs(blok.stats) do
		if opt.L then
			io.write('  ', combineer(stat), '\t\t')
			io.flush()
		end
		-- naam := exp
		-- naam := f(a,b)
		local naam,exp = stat[1],stat[2]
		local uit
	
		local exp = emap(exp, waarde, env)
		local w
		if isatoom(exp) then
			if exp.v == '[]' then
				w = {}
			else
				w = exp.w
			end
		elseif fn(exp) == '_arg' then
			local t = {...}
			w = t[1] or "FOUT"
		elseif exp.fn and type(exp.fn.w) == 'table' then
			-- woeps
			local a = exp.fn.w
			local i = exp[1].w
			w = a[i+1]
			local f = componeer(w2exp, combineer)
			assert(w ~= nil, f(a) .. '.' .. f(i))

		elseif exp.fn == '_fn' then
			w = env[fn(exp)]
			
		else
			local func = exp.fn.w
			assert(func ~= nil, "geen functie voor "..e2s(exp.fn))
			local args = {}
			for i,s in ipairs(exp) do
				args[i] = s.w
			end
			if type(func) == 'function' then
				--w = func(able.unpack(args))
				local ok
				ok, w = pcall(func, table.unpack(args))
				if not ok then
					local err = w
					local f = executiefout(stat.loc, err)
					print(fout2ansi(f))
					return
				end

			elseif type(func) == 'table' then
				w = func[args[1]]

			else
				local f = executiefout(stat.loc, 'onbekend index type: '..type(func))
				print()
				print(fout2ansi(f))
			end

		end
		if opt.L then
			if true or type(w) ~= 'table' then
				io.write(combineer(w2exp(w)), '\t', loctekst(stat.loc), --[['\t', locsub(exp.code, stat.loc)]] '\n')
			else
				io.write('\t\t', loctekst(stat.loc), '\n')
			end
		end

		env[naam.v] = w
	end
	local epi = blok.epiloog
	if fn(epi) == 'ret' then
		local a = env[blok.stats[#blok.stats][1].v]
		if opt.L then print('ret '..a) end
		return a
	elseif epi.v == 'stop' then
		local a =  env[blok.stats[#blok.stats][1].v]
		if opt.L then print('stop') end
		os.exit()
	elseif fn(epi) == 'ga' then
		local a,d,e = epi[1], epi[2], epi[3]
		if #epi == 3 then
			local b = env[a.v]
			local doel = b and d.v or e.v
			if opt.L then print(string.format('ga %s want %s = %s', doel, a.v, b)) end
			assert(type(b) == 'boolean', 'sprongkeuze is niet binair: '..combineer(epi))
			return env[doel](...)
		else
			if opt.L then print('ga '..a.v) end
			return env[a.v](...) -- sws jmp
		end
	else
		error('slechte epiloog: '..combineer(epi))
	end
end

function doe(cfg)
	local env = {}
	for k,v in pairs(bieb) do env[k] = v end
	for k,v in pairs(cfg.namen) do
		env[k] = function(...)
			local isf = k:sub(1,2) == 'fn'
			if isf and opt.L then print('...') ; print('call '..k); end
			local ret = doeblok(v, env, ...)
			if opt.L then 
				if isf then io.write('\n...') end
				io.flush()
			end
			return ret
		end
	end

	-- GA
	doeblok(cfg.start, env)

	local uit
	if type(env.A) == 'table' then
		uit = taal2string(env.A)
	else
		uit = tostring(env.A)
	end
	print(uit)
	--for k,v in pairs(env) do print(k,v) end
end
