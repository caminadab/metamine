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
		if verbozeIntermediair then
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
			local a = exp[1].w
			local b = exp.fn.w
			w = b[a+1]
			local f = componeer(w2exp, combineer)
			assert(w ~= nil, f(b) .. '.' .. f(a))

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
				--w = func(table.unpack(args))
				local ok
				ok, w = pcall(func, table.unpack(args))
				if not ok then
					local err = w
					local f = executiefout('{loc}', stat.loc)
					print()
					print(fout2ansi(f))
					return
				end

			elseif type(func) == 'table' then
				w = func[args[1]]

			else
				local f = executiefout('{loc}', stat.loc)
				print()
				print(fout2ansi(f))
			end

		end
		if verbozeIntermediair then
			if type(w) ~= 'table' then
				io.write(combineer(w2exp(w)), '\t', loctekst(stat.loc), '\n')
			end
		end

		env[naam.v] = w
	end
	local epi = blok.epiloog
	if fn(epi) == 'ret' then
		return env[blok.stats[#blok.stats][1].v]
	elseif fn(epi) == 'ga' then
		local a,d,e = epi[1], epi[2], epi[3]
		if #epi == 3 then
			if env[a.v] then
				print('ga '..d.v)
				return env[d.v](...) -- dan 
			else
				print('ga '..e.v)
				return env[e.v](...) -- anders
			end
		else
			print('ga '..a.v)
			return env[a.v](...) -- sws jmp
		end
	end
end

function doe(cfg)
	local env = {}
	for k,v in pairs(bieb) do env[k] = v end
	for k,v in pairs(cfg.namen) do env[k] = function(...) return doeblok(v, env, ...) end end

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
