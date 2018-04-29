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

function eqsolve(eq,t)
	local t = t or {}
	for var in spairs(varset(eq)) do
		local exp = rewrite(eq,var)
		if exp then
			--log(var..' := '..unlisp(exp))
			t[#t+1] = {':=', var, exp}
		end
	end
end

-- officieuze graaf!
-- graaf = { node }
-- node = (from: {node}, to: {node}, name, exp)
function ass2graph(ass)
	-- init
	local p = {}
	for n in pairs(ass) do
		p[n] = p[n] or {to={},from={},name=n}
	end
	return p
end

function loggraph(graph)
	for n,v in spairs(graph) do
		io.write(n, ' -> ')
		for w in spairs(v.to) do
			io.write(w, ' ')
		end
		io.write('\n')
	end
end

function hascycles(graph)
	local index = 1
	local s = {}
	local strong = {}
	local cycle = false

	function strongconnect(v)
		v.index = index
		v.lowlink = index
		index = index + 1
		s[#s+1] = v
		v.onstack = true

		for n,w in pairs(v.to) do
			if not w.index then
				strongconnect(w)
				v.lowlink = math.min(v.lowlink, w.lowlink)
			elseif w.onstack then
				v.lowlink = math.min(v.lowlink, w.index)
			end
		end

		if v.lowlink == v.index then
			local st = {}
			local w
			repeat
				w = s[#s]
				s[#s] = nil
				w.onstack = false
				st[#st+1] = w.name
			until w == v
			if #st > 1 then
				cycle = true
			end
		end
	end

	for n,v in pairs(graph) do
		v.index,v.lowlink,v.onstack = nil,nil,false
	end

	for n,v in pairs(graph) do
		if not v.index then
			strongconnect(v)
		end
	end
	
	return cycle
end


-- ass -> flow
function solve(ass,val)
	log('FLOW GENEREREN')
	local graph = ass2graph(ass)
	local old = {}
	local todo = {val}
	local flow = {}
	local done = {}

	while #todo > 0 do
		local name = todo[#todo]
		todo[#todo] = nil

		local exps = dep[name] or {}
		--log(#exps .. 'mogelijkheden')

		-- vind geldig systeem
		local ok
		local edges = {}
		for i,exp in ipairs(exps) do
			for v in pairs(varset(exp)) do
				if graph[v] and not graph[v].to[name] then
					edges[#edges+1] = {v,name}
					graph[name].from[v] = graph[v]
					graph[v].to[name] = graph[name]
				end
			end
			local y = hascycles(graph)
			if not y then
				ok = exp
				break
			else
				-- remove edges
				for i,edge in ipairs(edges) do
					local from,to = edge[1],edge[2]
					graph[from].to[to] = nil
					graph[to].from[from] = nil
				end
			end
		end

		if ok then
			flow[#flow+1] = {':=', name, ok}
			for to in spairs(varset(ok)) do
				if not done[to] then
					todo[#todo+1] = to
					done[to] = true
				else
					-- ververs
					for i=1,#flow do
						if flow[i][2] == to then
							print('VERPLAATS')
							local stat = flow[i]
							print(i, #flow, unlisp(stat))
							--table.insert(flow, #flow-2, stat)
							local dep = table.remove(flow, i)
							table.insert(flow, dep)
							break
						end
					end
				end
			end
		else
			log('GEEN OPLOSSING GEVONDEN VOOR '..name)
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
		for name in pairs(varset(x)) do
			if sec[name] or tijd[name] == 'sec' then
				t = 'sec'
			end
		end

		tijd[n] = t
		stat.tijd = t
	end

	-- sorteer
	local const,sec,analog = {'const'},{'sec'},{'analog'}
	local blocks = {}
	for i,block in ipairs(proc) do
		if block.tijd == 'const' then
			const[#const+1] = block
		elseif block.tijd == 'sec' then
			sec[#sec+1] = block
		else
			log('niet tijdsgebonden: '..unlisp(block))
			analog[#analog+1] = block
		end
	end
	if #const > 1 then table.insert(blocks,const) end
	if #sec > 1 then table.insert(blocks,sec) end
	if #analog > 1 then table.insert(blocks,analog) end

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

-- resolve equations
dep = {}
ass = {}
for i,eq in spairs(sas) do
	eqsolve(eq,ass)
end

for i,as in ipairs(ass) do
	local n,v = as[2],as[3]
	dep[n] = dep[n] or {}
	table.insert(dep[n], v)
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
