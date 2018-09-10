require 'lisp'
require 'util'

local log = function() end

local fn = {
	['+'] = function(a,b) return a + b end;
	['-'] = function(a,b) if b then return a - b else return -a end end;
	['*'] = function(a,b) return a * b end;
	['/'] = function(a,b) return a / b end;
	['^'] = function(a,b) return a ^ b end;
	['[]'] = function(...)
		return table.pack(...)
	end,

	['#'] = function(a) return #a end;
	['='] = function(a,b) return unlisp(a)==unlisp(b) end;
	['..'] = function(a,b)
		local r = {}
		for i=a,b-1 do
			r[i-a+1] = i
		end
		return r
	end;

	['||'] = function(a,b)
		local j = 1
		local t = {}
		for i,v in ipairs(a) do t[j] = v; j=j+1 end
		for i,v in ipairs(b) do t[j] = v; j=j+1 end
		return t
	end;

	-- lib
	['cat'] = function(a,b)
		local r = {}
		for i,v in ipairs(a) do
			for i,v in ipairs(v) do
				r[#r+1] = v
			end
			if b then
				r[#r+1] = b
			end
		end
		return r
	end;

	['som'] = function(a)
		local r = 0
		for i,v in ipairs(a) do
			r = r + v
		end
		return r
	end;

	['herhaal'] = function(a,n) -- 10
		local r = {}
		for i=1,n do
			r[i] = a
		end
		return r
	end;

	['tekst'] = function(a)
		if type(a) == 'table' then
			a = unlisp(a)
		end
		return table.pack(string.byte(tostring(a),1,#tostring(a)))
	end;

	['getal'] = function(a)
		return tonumber(string.char(table.unpack(a)))
	end;

	['split'] = function(a,b)
		local r = {}
		local t = {}
		for i,v in ipairs(a) do
			if v == b then
				r[#r+1] = t
				t = {}
			else
				t[#t+1] = v
			end
		end
		return r
	end;
}

function eval0(env,exp)
	if atom(exp) then
		local v = tonumber(exp) or env[exp] or fn[exp]
		if not v then error('onbekend: "'..unlisp(exp)..'"') end
		return v
	else
		local r = {}
		for i=1,#exp do
			r[i] = eval0(env,exp[i])
		end
		local f,a,b = r[1],r[2],r[3]
		
		-- tabel
		if type(r[1]) == 'table' then
			return f[a+1]
		end

		-- aanroep
		if type(r[1]) ~= 'function' then
			error('geen functie: '..tostring(f)..' '..unlisp(exp))
		end

		-- functie
		local t = {}
		for i=2,#r do t[i-1] = r[i] end
		return f(table.unpack(t))
	end
end

function eval(proc)
	log('# Eval')
	log()
	local stdin = ''
	local env = {stdin = table.pack(string.byte(stdin,1,-1))}
	for i,block in ipairs(proc) do
		local header = block[1]
		local dim = tonumber(header[2])

		if dim == 0 then
			local env0 = evalblock(env,block)
			for k,v in spairs(env0) do
				env[k] = v
			end
			log()

		elseif dim == 1 then

			-- laat ons gaan
			for i=2,#block do
				local stat = block[i]
				local name,exp = stat[2],stat[3]
				local res = {}
				local index = 1
				local done = false

				repeat
					local sub = {}
					for i,v in ipairs(exp) do
						v = env[v] or v
						if atom(v) then
							sub[i] = v
						else
							if not v[index] then
								done = true
							else
								sub[i] = v[index]
							end
						end
					end

					if not done then
						res[index] = eval0(env,sub)
						index = index + 1
					end
				until done

				log('',name,':= '..unlisp(res))
				env[name] = res
			end
			log()

		-- tijd
		elseif block[1] == 'sec' then
			for i=1,10 do
				slaap(1)
				log('#'..i)
				evalblock(env,block)
			end
		else
			error('hoe kan ik '..unlisp(block)..' evalueren?')
		end
	end
	return env.stdout
end

function array(block,off)
	off = off or 1
	return function()
		local b = block[off]
		off = off + 1
		return b
	end
end

function evalblock(env,block)
	local env = copy(env)
	local env0 = {}
	for stat in array(block,2) do
		local name,val = stat[2],stat[3]
		env0[name] = eval0(env,val)
		env[name] = env0[name]
		log('',name,':= '..unlisp(env[name]))
	end
	return env0
end

function equals(a,b)
	do return unlisp(a) == unlisp(b) end
	if type(a) == 'table' and type(b) == 'table' then
		if #a ~= #b then return false end
		for i,a0 in ipairs(a) do
			if not equals(a0,b[i]) then
				return false
			end
		end
		return true
	else
		return a == b
	end
end

-- test
if false and test then
	local t = {
		{'((:= stdout 0))', 0},
		{'((:= a 0) (:= stdout a))', 0},
		{'((:= stdout (cat ([] ([] 0) ([] 1 2))) ))', '(0 1 2)'},
		{'((:= stdout (+ 1 1) ))', '2'},
	}
	for i,v in ipairs(t) do
		local q = v[1]
		local a = v[2]
		local r = eval(lisp(q))
		assert(equals(r,a), q .. ' geeft ' .. unlisp(r) .. ', maar hoort te zijn ' .. unlisp(a))
	end
end

function doe(stroom)
	local env = {}
	for i,noem in ipairs(stroom) do
		local naam,exp = noem[2],noem[3]
		print('DOE', leed(noem))

		-- lus
		if type(naam) == 'table' then
			local naam,itnaam = naam[1],naam[2]
			local it = env[itnaam]
			if not it or type(it) ~= 'table' then
				error('ongeldige lus '..itnaam)
			end

			env[naam] = env[naam] or {}
			local naar = env[naam]

			for i = 1,#it do
				print('it', it[i])
				env[itnaam] = it[i]
				print('eval0', unlisp(exp))
				naar[i] = eval0(env, exp)
				print('naar',naar[i])
			end
			env[it] = nil

		-- geen lus
		else
			env[naam] = eval0(env, exp)

		end
		print('GEDAAN',unlisp(env[naam]))
	end

	local uit = env['uit']
	if type(uit) == 'table' then
		uit = string.char(table.unpack(uit))
	end
	return uit
end
