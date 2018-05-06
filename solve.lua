#!/usr/bin/lua
require 'lisp'
require 'func'
require 'rewrite'

local colors = {
	init = color.green,
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
	local graph = ass2graph(ass)
	local old = {}
	local todo = {val}
	local flow = {}
	local done = {}

	while #todo > 0 do
		local name = table.remove(todo, 1)

		local exps = ass[name] or {}
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
							local stat = flow[i]
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

	log('# Solve: Ass -> Flow')
	for i,v in ipairs(flow) do
		log(v[2], ' := '..unlisp(v[3]))
	end
	log()
		
	return flow, {}
end

init = {
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
	
function Plan(proc)
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
		local t = 'init'
		for name in pairs(varset(x)) do
			if sec[name] or tijd[name] == 'sec' then
				t = 'sec'
			end
		end

		tijd[n] = t
		stat.tijd = t
	end

	-- sorteer
	local init,sec,analog = {'init'},{'sec'},{'analog'}
	local blocks = {}
	for i,block in ipairs(proc) do
		if block.tijd == 'init' then
			init[#init+1] = block
		elseif block.tijd == 'sec' then
			sec[#sec+1] = block
		else
			log('niet tijdsgebonden: '..unlisp(block))
			analog[#analog+1] = block
		end
	end
	if #init > 1 then table.insert(blocks,init) end
	if #sec > 1 then table.insert(blocks,sec) end
	if #analog > 1 then table.insert(blocks,analog) end

	log('# Plan: Ass -> Proc')
	logproc(blocks)
	log('')
	return blocks
end

-- negeer tijd
function plan2(proc)
	local dim,loop = dim(proc)

	log('# Dimensionaliteit')
	for n,v in spairs(loop) do
		log('dim '..n,':= '..unlisp(v)..' **'..dim[n])
	end
	log()

	-- dim -> block
	local blocks = {}
	local prev
	local block = {}
	for i,v in ipairs(proc) do
		local name,exp = v[2],v[3]
		local dim,loop = dim[name],loop[name] or {}
		if unlisp(prev) ~= unlisp(loop) then
			if #block > 0 then blocks[#blocks+1] = block end
			prev = loop
			if #loop > 0 and exp[1] ~= '||' and exp[1] ~= '[]' then
				block = {{'loop', table.unpack(loop)}}
			else
				block = {'init'}
			end
		end
		block[#block+1] = v
	end
	if #block > 0 then blocks[#blocks+1] = block end

	log('# Plan')
	for i,block in ipairs(blocks) do
		for i,stat in ipairs(block) do
			log(unlisp(stat))
		end
		log()
	end
	log()
	return blocks
end

function plan(proc)
	local blocks = {}
	local prev
	local dims,dodims = dim(proc)

	for i,v in ipairs(proc) do
		local name,exp = v[2],v[3]
		-- nieuw blok
		if dodims[name] ~= prev then
			blocks[#blocks+1] = {{'dim',dodims[name]}}
			prev = dodims[name]
		end

		-- wij
		local block = blocks[#blocks]
		block[#block+1] = v
	end

	log('# Plan')
	for i,block in ipairs(blocks) do
		log('dim '..block[1][2])
		for i=2,#block do
			local stat = block[i]
			log(stat[2],':= '..unlisp(stat[3]))
		end
		log()
	end
	log()

	return blocks
end

function logproc(proc)
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
function ass(eqs)
	local dep = {}
	local ass = {}
	for i,eq in spairs(eqs) do
		eqsolve(eq,ass)
	end
	
	for i,as in ipairs(ass) do
		local n,v = as[2],as[3]
		dep[n] = dep[n] or {}
		table.insert(dep[n], v)
	end
	return dep
end

-- type -> text
function ttoa(v)
end

local arit = {
	['^'] = true, ['_'] = true,
	['*'] = true, ['/'] = true,
	['+'] = true, ['-'] = true,
}

function approx(env,v)
	if atom(v) then
		if tonumber(v) then return tonumber(v)
		elseif env[v] then return env[v]
		else return 'int' end
	else
		local fn = v[1]
		if fn == '[]' then
			local r = {}
			for i=2,#v do
				r[i-1] = approx(env,v[i])
			end
			return r
		end
		if arit[fn] then
			-- a = b
			local a = approx(env,v[2])
			local b = approx(env,v[3])
			if type(a) == 'table' and type(b) == 'table' then
				if #a ~= #b then
					return 'error', 'table size mismatch'
				end
				local v = {}
				for i=1,#a do
					v[i] = approx(env,{fn, approx(a[i]), approx(b[i])})
				end
				return v
			end
			if type(a) == 'table' then
				local v = {}
				for i,v in ipairs(a) do
					v[i] = approx(env,{fn,a[i],b})
				end
				return v
			end
			if type(b) == 'table' then
				local v = {}
				for i,v in ipairs(b) do
					v[i] = approx(env,{fn,a,b[i]})
				end
				return v
			end
			
			-- actueel !! L.O.L.
			if a == 'int' or b == 'int' then
				return 'int'
			end
			if tonumber(a) and tonumber(b) then
				return func[fn](tonumber(a),tonumber(b))
			end
			do
				log('FOUT!', unlisp(a), unlisp(b))
			end
		end
	end
end

local fndim = {
	['^'] = 0, ['_'] = 0,
	['*'] = 0, ['/'] = 0,
	['+'] = 0, ['-'] = 0,

	['[]'] = 1, ['som'] = -1,
}

-- dimensionaliteit
function dimrec(env,exp)
	if atom(exp) then
		return env[exp] or 0, 0
	else
		local d = fndim[exp[1]]
		if not d then log('ONGELDIGE FUNCTIE '..d) end
		local m = 0
		for i=2,#exp do
			m = math.max(m,dimrec(env,exp[i]))
		end
		return d + m, d
	end
end

function Dim(f)
	log('# Dimensionaliteit')
	local env = {}
	local deltas = {}
	for i,stat in pairs(f) do
		local name,exp = stat[2],stat[3]
		local dim,delta = dimrec(env,exp)
		if not dim then
			error('KON DIMENSIONALITEIT NIET DEDUCEREN VAN '..unlisp(exp))
		end
		env[name] = dim
		deltas[name] = delta
		log('dim '..name,':= '..dim..' (+'..delta..')')
	end
	log()
	return env, delta
end

function dim0(asm)
	local dim,loop = {},{}
	for i,as in ipairs(asm) do
		local name,exp = as[2],as[3]
		local dim0 = 0
		local loop0 = {}
		if atom(exp) then
			dim0,loop0 = dim[exp],loop[exp]
		end
		-- vorige
		for i=1,#exp do
			local arg = exp[i]
			--log('arg', arg, dim[arg])
			if dim[arg] and dim[arg] > 0 then
				dim0 = dim[arg]

				--loop0[#loop0+1] = arg
				loop0[1] = arg
				for i,v in ipairs(loop[arg]) do
					--loop0[#loop0+1] = v
				end

			end
		end
		-- zelf
		if exp[1] == '[]' then
			--dim[#dim+1] = name
			dim0 = dim0 + 1
		elseif exp[1] == 'som' then
			dim0 = dim0 - 1
		end
		dim[name],loop[name] = dim0,loop0
	end
	return dim,loop
end

function dim(asm)
	local dims = {stdin = 1}
	local dodims = {}
	for i,as in ipairs(asm) do
		local name,exp = as[2],as[3]

		local dim,dodim = 0,0

		if atom(exp) then
			dim = dims[exp] or 0
			dodim = 0

		else
			local fn = exp[1]

			-- echte dim
			for i,v in ipairs(exp) do
				if dims[v] and dims[v] > 0 then
					dodim = 1
					dim = 1
				end
			end

			-- neppers
			if dims[fn] == 1 then
				if dims[exp[2]] == 1 then
					dodim = 0
					dim = 1
				else
					dodim = 0
					dim = 0
				end
			end
			if fn == '||' then
				dodim = 0
				dim = 1
			end
			if fn == '..' then
				dodim = 0
				dim = 1
			end
			if fn == '#' then
				dodim = 0
				dim = 0
			end
			if fn == '[]' then
				if dodim == 1 then
					error('geneste lijsten zijn nog niet ondersteund: '..name)
				end
				dodim = 0
				dim = 1
			end
		end

		dims[name],dodims[name] = dim,dodim
	end
	return dims,dodims
end

-- gegeven een (benoemde) expressie
-- voeg simpele ops aan asm toe
-- zoals (+ 1 tijd0)
function unravelrec(exp,name,asm,g)
	local aname = name
	if g then aname = name .. g end
	local g = g or -1
	g = g + 1
	if atom(exp) then
		asm[#asm+1] = {':=', aname, exp}
	else
		-- subs
		local args = {}
		for i,sub in ipairs(exp) do
			if atom(sub) then
				args[i] = sub
			else
				args[i] = name..g
				g = unravelrec(sub,name,asm,g)
			end
		end
		-- zelf
		asm[#asm+1] = {':=', aname, args}
	end
	return g
end

-- [(:= name exp)] -> [(:= name0 fn)]
function unravel(flow)
	local asm = {}
	for i,v in ipairs(flow) do
		local name,exp = v[2],v[3]
		unravelrec(exp,name,asm)
	end

	local log = function()end
	log('# Unravel')
	for i,v in ipairs(asm) do
		log(v[2],':= '..unlisp(v[3]))
	end
	log()

	return asm
end

eqs = lisp(io.read('*a'))
as = ass(eqs)
flow,un = solve(as, 'stdout')
asm = unravel(flow)
if dim(asm).stdout ~= 1 then
	error('stdout moet een lijst zijn: '..unlisp(dim(flow).stdout))
end
plan = plan(asm)
print(unlisp(plan))

for i,un in ipairs(un) do
	if string.upper(un) ~= un then
		log('ONBEKENDE VARIABEL '..un)
	end
end
