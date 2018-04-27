#!/usr/bin/lua
require 'lisp'

local fn = {
	['+'] = function(a,b) return a + b end;
	['-'] = function(a,b) if b then return a - b else return a end end;
	['*'] = function(a,b) return a * b end;
	['/'] = function(a,b) return a / b end;
	['^'] = function(a,b) return a ^ b end;
	['[]'] = function(...) return table.pack(...) end;

	['~'] = function(a,b)
		local t = {}
		for i,v in ipairs(a) do t[#t+1] = v end
		for i,v in ipairs(b) do t[#t+1] = v end
		return t
	end;
}

function eval(env,exp)
	if atom(exp) then
		return tonumber(exp) or env[exp] or fn[exp] or 'unknown'
	else
		local r = {}
		for i=1,#exp do
			r[i] = eval(env,exp[i])
		end
		return r[1](r[2],r[3],r[4],r[5])
	end
end

proc = lisp(io.read('*a'))
env = {}
for i,stat in ipairs(proc) do
	local name,val = stat[2],stat[3]
	env[name] = eval(env,val)
end

local v = env.stdout or 'unknown'
if type(v) == 'table' then v = string.char(table.unpack(v)) end
print(v or 'unknown')
