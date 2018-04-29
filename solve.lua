#!/usr/bin/lua
require 'lisp'
require 'func'
require 'rewrite'

local sas = lisp(io.read('*a'))

local colors = {
	constant = color.green,
	['in'] = color.cyan,
	out = color.red,
	name = color.purple,
}

function isvar(name)
	if tonumber(name) then
		return false
	elseif string.upper(name) == name then
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

function varset(exp,t)
	local t = t or {}
	if atom(exp) then
		if isvar(exp) then
			t[exp] = true
		end
	else
		for i,s in ipairs(exp) do
			varset(s,t)
		end
	end
	return t
end

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

function eqsolve(eq,t)
	local t = t or {}
	log('OPLOSSEN',unlisp(eq))
	for var in spairs(varset(eq)) do
		local exp = rewrite(eq,var)
		log(var..' := '..unlisp(exp))
		t[#t+1] = {':=', var, exp}
	end
end

-- resolve equations
--[[
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
]]
dep = {}
ass = {}
for i,eq in spairs(sas) do
	eqsolve(eq,ass)
end
for i,as in ipairs(ass) do
	print(unlisp(as))
end

for i,as in ipairs(ass) do
	local n,v = as[2],as[3]
	dep[n] = dep[n] or {}
	table.insert(dep[n], v)
end

-- ass -> flow
function solve(ass,val)
	local old = {}
	local todo = {val}
	local flow = {}

	while #todo > 0 do
		local name = todo[#todo]
		todo[#todo] = nil
		log('onderzoeken',name)

		local exps = dep[name]
		log(#exps .. ' mogelijkheden')

		-- vind geldig systeem
		local good
		for i,exp in ipairs(exps) do
			local ok = true
			for v in pairs(varset(exp)) do
				if old[v] or v == name then
					ok = false
					log('fout:',unlisp(v))
					break
				end
			end
			if ok then
				good = exp
				break
			end
		end

		if good then
			flow[#flow+1] = {':=', name, good}
			log('goed:',unlisp(flow[#flow]))
			for to in pairs(varset(good)) do
				if not old[to] then
					todo[#todo+1] = to
					old[to] = true
				end
			end
		end
	end

	local flow = reverse(flow)

	-- dubbelen
	local set = {}
	local r = {}
	for i=1,#flow do
		if flow[i] then
			local stat = flow[i]
			local n,v = stat[2],stat[3]
			if not set[n] then
				r[#r+1]  = flow[i]
			end
			set[n] = true
		end
	end
		
	return flow, {}
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

sec = {
	['tijd'] = true,
	['toetsLinks'] = true,
	['toetsRechts'] = true,
	['toetsOmhoog'] = true,
	['toetsOmlaag'] = true,
}
	
function plan(proc)
	-- start
	for i,v in ipairs(proc) do
		v.tijd = '?'
		local val = v[2]
		if sec[val] then
			v.tijd = 'sec'
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
			if sec[n] then
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
	for i,block in ipairs(proc) do
		if block.tijd == 'const' then
			const[#const+1] = block
		elseif block.tijd == 'sec' then
			sec[#sec+1] = block
		else
			log('niet tijdsgebonden: '..unlisp(block))
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

for i,un in ipairs(un) do
	if string.upper(un) ~= un then
		log('ONBEKENDE VARIABEL '..un)
	end
end
