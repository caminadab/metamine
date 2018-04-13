#!/usr/bin/lua
require 'lisp'

local fn = {
	['+'] = function(a,b) return a + b end;
	['*'] = function(a,b) return a * b end;
	['/'] = function(a,b) return a / b end;
	['^'] = function(a,b) return a ^ b end;
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

print(env.stdout or 'unknown')
