require 'util'
require 'combineer'

local map = {
	["+"] = "add",
	["-"] = "neg",
	["·"] = "mul",
	["/"] = "div",
	["^"] = "pow",
	["√"] = "sqrt",
	["‖"] = "cat",
	["#"] = "len",
	["_"] = "call",
	["|"] = "opt",
	["∘"] = "comp",
	["¬"] = "not",
	["∨"] = "or",
	["∧"] = "and",
	--[","] = "mul",
}
local rmap = {}
for k,v in pairs(map) do
	rmap[v] = k
end

-- mapt sub naar expdiepte
function diepte(exp)
	local d = {}
	local function f(exp, i)
		d[exp] = i
		for k,sub in subs(exp) do
			f(sub, i+1)
		end
	end
	f(exp,0)
	return d
end

function functioneel(exp)
	local todo = {exp}
	local stack = {}
	local i = {}

	local proc = {}
	local d = diepte(exp)
	local dieptes = {} -- functiedieptes

	while #todo > 0 do
		local p = table.remove(todo)
		for k,sub in subs(p) do
			if fn(p) ~= "_arg" and fn(p) ~= "_fn" then
				--todo[#todo+1] = sub
				table.insert(todo, sub)
				if fn(sub) == '_fn' then
					dieptes[arg(sub).v] = d[sub]
				end
			end
		end

		-- naar proc
		if isatoom(p) then
			push(proc, "push "..(map[p.v] or p.v))
		elseif fn(p) == '_fn' then
			local i = arg(p).v
			dieptes[i] = d[p]
		elseif fn(p) == '_arg' then
			local i = arg(p).v
			assert(dieptes[i], string.format("functie %d met diepte %d bestaat niet", i, d[p]))
			local base = dieptes[i]
			local zelf = d[p]
			push(proc, "arg "..tostring(zelf - base).." ; zelf="..zelf..", base="..base)
		elseif isobj(p) then
			if p == 2 then
				if not rmap[proc[#proc]] then
					proc[#proc] = 'f'..proc[#proc]
					push(proc, "agg "..#p)
				end
			end
		elseif fn(p) == '_' and fn(arg0(p)) == '_fn' then
			-- neits
		elseif map[fn(p)] then
			push(proc, map[fn(p)])
		else
			print('huh?', fn(p))
			push(proc, fn(p))
		end
	end

	for i=#proc,1,-1 do
		print(proc[i])
	end
end
