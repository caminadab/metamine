#!/usr/bin/lua5.2
require 'lisp'
require 'util'

local stdin
local fn = {
	['+'] = function(a,b) return a + b end;
	['-'] = function(a,b) if b then return a - b else return a end end;
	['*'] = function(a,b) return a * b end;
	['/'] = function(a,b) return a / b end;
	['^'] = function(a,b) return a ^ b end;
	['[]'] = function(...) return table.pack(...) end;
	['#'] = function(a) return #a end;
	['..'] = function(a,b)
		local r = {}
		for i=a,b-1 do
			r[#r+1] = i
		end
		return r
	end;

	['||'] = function(a,b)
		local t = {}
		for i,v in ipairs(a) do t[#t+1] = v end
		for i,v in ipairs(b) do t[#t+1] = v end
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

	['herhaal'] = function(a,n) -- 10
		local r = {}
		for i=1,n do
			r[i] = a
		end
		return r
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

setmetatable(fn, {
	__index = function(t,v)
		if v == 'stdin' then
			stdin = stdin or io.read('*a')
			if type(stdin) == 'string' then
				stdin = table.pack(string.byte(stdin))
			end
			return stdin
		elseif v == 'tijd' then
			return os.time()
		end
	end;
})

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
		if type(r[1]) == 'table' then
			local x = {}
			if type(r[2]) == 'number' then
				x = r[1][r[2]+1]
			else
				for i,v in ipairs(r[2]) do
					x[#x+1] = r[1][v+1]
				end
			end
			return x
		end
		if type(r[1]) ~= 'function' then
			error('geen functie: '..tostring(r[1])..' '..unlisp(exp))
		end
		local t = {}
		for i=2,#r do t[i-1] = r[i] end
		return r[1](table.unpack(t))
	end
end

function eval(proc)
	log('# Eval')
	log()
	local stdin = io.read('*a')
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
if test then
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

-- a
path = ...
if path then
	app = file(path)
	proc = lisp(app)
	v = eval(proc)

	if not v then
		error('geen uitvoer')
	end
	if type(v) == 'table' then v = string.char(table.unpack(v)) end
	io.write(v)
end
