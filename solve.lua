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
function solve(dep,val)
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

function isvar(name)
	if tonumber(name) then
		return false
	end
	return true
end

function var(exp,t)
	t = t or {}
	if atom(exp) then
		if isvar(exp) then
			t[#t+1] = exp
		end
	else
		for i,s in ipairs(exp) do
			var(s,t)
		end
	end
	return t
end

const = {
	['*'] = true,
	['+'] = true,
	['*'] = true,
	['-'] = true,
	['/'] = true,
	['^'] = true,
	['.'] = true,

	['[]'] = true,
	['cat'] = true,
	['split'] = true,
}
	
function plan(proc)
	-- start
	for i,v in ipairs(proc) do
		local val = v[2]
		if val == 'tijd' then
			v.tijd = 'sec'
		else
			v.tijd = '?'
		end
	end

	-- doorloop
	local sources = {}
	local tijd = {}
	for i,stat in ipairs(proc) do
		n = stat[2]
		v = stat[3]
		x = var(v)

		-- logica
		local t = 'const'
		for i,n in ipairs(x) do
			-- constant?
			if not const[n] and tijd[n] ~= 'const' then
				t = 'analoog'
			end
			if n == 'tijd' then
				t = 'sec'
			end
			if tijd[n] == 'sec' then
				t = 'sec'
			end
		end
		stat.tijd = t
		tijd[n] = t
	end

	-- sorteer
	local const,sec = {'const'},{'sec'}
	local blocks = {}
	for i,stat in ipairs(proc) do
		if stat.tijd == 'const' then
			const[#const+1] = stat
		elseif stat.tijd == 'sec' then
			sec[#sec+1] = stat
		end
	end
	if #const > 1 then table.insert(blocks,const) end
	if #sec > 1 then table.insert(blocks,sec) end

	return blocks
end

function printflow(proc)
	for i,block in ipairs(proc) do
		local tijd = block[1]
		log(color.green..tijd..color.white)
		for i,vd in ipairs(block) do
			if i > 1 then
				local val,dep = vd[2],vd[3]
				log(val..' := '..unlisp(dep)..'\t')
			end
		end
		log('\n')
	end
end


f,un = solve(dep, 'stdout')
p = plan(f)
printflow(p)
print(unlisp(p))

-- onbekenden
for i,un in ipairs(un) do
	if string.upper(un) ~= un then
		log('ONBEKENDE VARIABEL '..un)
	end
end
