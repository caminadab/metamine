#!/usr/bin/lua
require 'lisp'
require 'func'

local sas = lisp(io.read('*a'))

function label(exp)
	if atom(exp) then
		if exp == 'stdout' then return 'out' end
		if exp == 'stdin' then return 'in' end
		if tonumber(exp) then return 'constant' end
		if string.upper(exp) == exp then return 'constant' end
		return 'name'
	else
		return map(exp, label)
	end
end

local colors = {
	constant = color.green,
	['in'] = color.cyan,
	out = color.red,
	name = color.purple,
}

function contains(exp, name)
	if atom(exp) then
		return exp == name
	else
		for i,v in ipairs(exp) do
			if contains(v,name) then return true end
		end
		return false
	end
end

function resolve(eqs,name,skip)
	local r
	for i,eq in spairs(sas) do
		local a,b = eq[2],eq[3]
		if not skip[a] and not skip[b] then
			if b == name then a,b = b,a end
			if not contains(b,a) then
				if a == name then r = b end
			end
		end
	end
	return r
end

function putdeps(sas,un,dep,todo)
	if not dep[un] then
		if atom(un) then
			sym = resolve(sas,un,dep)
			if sym then
				dep[un] = sym
				todo[sym] = true
			else
				--print('unresolvable '..un)
			end
		else
			for i,sub in ipairs(un) do
				putdeps(sas,sub,dep,todo)
			end
		end
	end
end

-- resolve equations
dep = {}
todo = {['stdout'] = true}
while next(todo) do
	todo1 = {}
	--io.write('TODO: '); for k in pairs(todo) do io.write(unlisp(k), ' ') end; io.write('\n')
	for un in spairs(todo) do
		putdeps(sas,un,dep,todo1)
	end
	todo = todo1
end

-- val,deps -> [ val i := dep i ]
function flow(dep,val)
	local flow = {{':=', val, dep[val]}}
	local todo = {dep[val]}
	local un = {}
	while #todo > 0 do
		local val = todo[#todo]
		todo[#todo] = nil

		if atom(val) then
			if dep[val] then
				flow[#flow+1] = {':=', val, dep[val]}
				todo[#todo+1] = dep[val]
			else
				un[#un+1] = val
			end
		else
			for i,v in ipairs(val) do
				todo[#todo+1] = v
			end
		end
	end
	return reverse(flow),un
end

function printflow(proc)
	for i,vd in ipairs(proc) do
		local val,dep = vd[2],vd[3]
		print(val..' := '..unlisp(dep))
	end
end

f,un = flow(dep, 'stdout')
print(unlisp(f))

-- onbekenden
for i,un in ipairs(un) do
	if string.upper(un) ~= un then
		print('ONBEKENDE VARIABEL '..un)
	end
end
