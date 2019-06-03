require 'combineer'
require 'bieb'

local function waarde(a, env)
	if isatoom(a) then
		local w = tonumber(a.v) or env[a.v] or a.v == '_arg' or error('onbekend: '..tostring(a.v))
		a.w = w
	end
	return a
end

local function doeblok(blok, env, ...)
	for i,stat in ipairs(blok.stats) do
		print(combineer(stat), ...)
		-- naam := exp
		-- naam := f(a,b)
		local naam,exp = stat[1],stat[2]
		local uit
	
		local exp = emap(exp, waarde, env)
		local w
		if isatoom(exp) then
			w = exp.w
		elseif fn(exp) == '_arg' then
			local t = {...}
			w = t[1]
		else

			local func = exp.fn.w
			assert(func, "geen functie voor "..e2s(exp.fn))
			local args = {}
			for i,s in ipairs(exp) do
				args[i] = s.w
			end
			w = func(table.unpack(args))
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
				return env[d.v]()
			else
				return env[e.v]()
			end
		else
			return env[a.v]()
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
