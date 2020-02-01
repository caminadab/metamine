local socket = require 'socket'
require 'combineer'
require 'bieb'
require 'func'
require 'fout'

local function doeatoom(exp, bieb, env)
	if tonumber(exp.v) then
		return tonumber(exp.v)
	elseif bieb[exp.v] ~= nil then
		return bieb[exp.v]
	elseif env[exp.v] ~= nil then
		return env[exp.v]
	elseif isobj(exp) then
		local t = {}
		for i,sub in ipairs(exp) do
			t[i] = doeatoom(sub, bieb, env)
		end
		return t
	else
		--error('onbekend: '..combineer(exp))
		return nil
	end
end

local function doestat(stat, bieb, env)
	assert(env)
	local cmd = stat.a[2]

	if isobj(cmd) then
		local r = {}
		for i,v in ipairs(cmd) do
			r[i] = doeatoom(v, bieb, env)
		end
		return r
	
	elseif isatoom(cmd) then
		return doeatoom(cmd, bieb, env)

	elseif isfn(cmd) then
		local fn = bieb[fn(cmd)]
		local arg = doeatoom(arg(cmd), bieb, env)
		local res = fn(arg)

		return res
	
	else
		error('wat is dit: '..combineer(stat))

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

function doestats(app, bieb)
	local invbieb = {}
	for k,v in pairs(bieb) do invbieb[v] = k end
	local env = {}
	for i, stat in ipairs(app) do
		if opt and opt.L then
			io.write('  ', combineer(stat), '\t= ')
			io.flush()
		end
		local val = doestat(stat, bieb, env)
		local naam = atoom(arg0(stat))
		env[naam] = val
		if opt and opt.L then
			print(lenc(val))
		end
	end
	return env[atoom(arg0(app[#app]))], env
end

-- app: (nu, vars) → (uit, vars)
function doe(app)
	local bieb = bieb()
	local main,env = doestats(app, bieb)

	-- init
	local nu = socket.gettime()
	local start = true
	local vars = {}

	-- doe
	local res = main {vars, start, nu}
	local uit, vars = res[1], res[2]

	while true do
		-- update
		local nu = socket.gettime()
		local start = false

		-- doe
		local res = main {vars, start, nu}
		uit, vars = res[1], res[2]

		-- uit
		io.write(ansi.wisregel, ansi.regelbegin)
		io.write(uit, ' ')
		io.flush()
		socket.sleep(1/60)
	end

	return ret
end
