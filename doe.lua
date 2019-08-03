require 'combineer'
require 'bieb'
require 'func'
require 'fout'

local function waarde(a, env, ...)
	local t = {...}
	if fn(a) == '[]u' then
		--w = string.char(unpack(map(a, function(x) return tonumber(x) end)))
		--return a
	end
	if #t == 1 and type(t[1]) == 'table' then
		t = t[1]
	end
	for i,v in ipairs(t) do
		local arg = '_arg'..(i-1)
		--print('ARG', i, arg)
		env[arg] = v
	end
	if isatoom(a) then
		local w
		if w == nil then w = tonumber(a.v) end
		if w == nil then w = env[a.v] end
		if w == nil then
			w = (a.v and a.v:sub(1,4) == '_arg' and ({...})[a.v:sub(5,5) + 1]) or nil end
		if w == nil then 
			--error('onbekend: '..tostring(a.v))
		end

		a.w = w
	end
	assert(a.w ~= nil, 'onbekend: '..e2s(a))
	return a
end

local function doeblok(blok, env, ...)
	for i,stat in ipairs(blok.stats) do
		if opt and opt.L then
			-- locsub(exp.code, stat.loc), 
			io.write('  ', combineer(stat), '\t', loctekst(stat.loc), '\t\t' )
			io.flush()
		end
		-- naam := exp
		-- naam := f(a,b)
		local naam,exp = stat[1],stat[2]
		local uit
	
		local exp = emap(exp, waarde, env, ...)
		local w
		if isatoom(exp) then
			if exp.v == '[]' then
				w = {}
			else
				w = exp.w
			end
		elseif exp.fn and type(exp.fn.w) == 'table' then
			-- woeps
			local a = exp.fn.w
			local i = exp[1].w
			w = a[i+1]
			assert(w ~= nil, combineer(w2exp(a)) .. '.' .. combineer(w2exp(b)))

		elseif exp.fn.v == '_fn' then
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
				local f = executiefout(stat.loc, 'onbekende index: '..tostring(func)..' : '..type(func)..' ('..combineer(stat)..')')
				print()
				print(fout2string(f))
			end

		end
		assert(w ~= nil, 'Ontologiefout: '..combineer(exp) .. ' is niets')

		if opt and opt.L then
			io.write(combineer(w2exp(tostring(w))), '\n')
		end

		env[naam.v] = w
	end
	local epi = blok.epiloog
	if fn(epi) == 'ret' then
		local a = env[blok.stats[#blok.stats][1].v]
		if opt and opt.L then print('ret '..tostring(a)) end
		return a
	elseif epi.v == 'stop' then
		local a =  env[blok.stats[#blok.stats][1].v]
		if opt and opt.L then print('stop') end
		return a
	elseif fn(epi) == 'ga' then
		local a,d,e = epi[1], epi[2], epi[3]
		if #epi == 3 then
			local b = env[a.v]
			local doel = b and d.v or e.v
			if opt and opt.L then print(string.format('ga %s want %s = %s', doel, a.v, b)) end
			assert(type(b) == 'boolean', 'sprongkeuze is niet binair: '..combineer(epi))
			return env[doel](...)
		else
			if opt and opt.L then print('ga '..a.v) end
			return env[a.v](...) -- sws jmp
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
	for k,v in pairs(bieb) do env[k] = v end
	for k,v in pairs(cfg.namen) do
		env[k] = function(...)
			local isf = k:sub(1,2) == 'fn'
			if isf and opt and opt.L then print('...') ; print('call '..k..' '..table.concat(map({...}, function(x) return combineer(w2exp(x)) end), ' ')); end
			local ret = doeblok(v, env, ...)
			if opt and opt.L then 
				if isf then io.write('\n...') end
				io.flush()
			end
			return ret
		end
	end

	-- GA
	local ret = doeblok(cfg.start, env)
	return ret
end
