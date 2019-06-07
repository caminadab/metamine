require 'util'
local infix = set('*', '/', '+', '-', 'mod')

local aliases = {
	['..'] = '_toti',
}

local jsbiebbron = file('bieb/bieb.js')

local jsbieb = {}
for waarde, naam in jsbiebbron:gmatch('(var ([^ ]*) = .-\n)\n') do
	jsbieb[naam] = waarde
end

local function sym(exp, t)
	local f = fn(exp)
	local op = f and f:sub(1,-2)
	if infix[op] then
		t[#t+1] = exp[1].v .. op .. exp[2].v
	elseif op == '[]' then
		t[#t+1] = '[' .. table.concat(map(exp, function(sub) return sub.v end), ', ') .. ']'
	else
		if isatoom(exp) then
			t[#t+1] = exp.v
		else
			--t[#t+1] = f .. '(' .. exp[1].v .. ')' --table.concat(map(exp, function(sub) return sub.v end), ', ') .. ')'
			t[#t+1] = f .. '(' .. table.concat(map(exp, function(sub) return sub.v end), ', ') .. ')'
		end
	end
end

--[[
[]       -> []
[](1 2)  -> [1,2]
{}(1 2)  -> {1,2}
+(1 2)   -> 1 + 2
-(1)     -> - 1
sin(1)   -> Math.sin(1)
vanaf(a 1)   -> a.splice(1)
]]
function naarjavascript0(app)


function naarjavascript1(app)
	local t = {}
	local gebruikt = {}
	local function jsblok(blok)
		for i, stat in ipairs(blok.stats) do
			local res, exp = stat[1].v, stat[2]

			if isfn(exp) and aliases[fn(exp)] then
				exp.fn.v = aliases[fn(exp)]
			end

			t[#t+1] = 'var '..res..' = '
			sym(exp, t)
			t[#t+1] = ';\n'

			for naam in spairs(vars(stat[2])) do
				local naam = naam.v

				if jsbieb[naam] and not gebruikt[naam] then
					gebruikt[naam] = true
					table.insert(t, 1, jsbieb[naam])
				end
			end
		end
	end
	jsblok(app.start)
	return table.concat(t)
end
