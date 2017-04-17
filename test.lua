require 'sexpr'
require 'optimize'
local builtin = require 'builtin'

function isdefined(s)
	return tonumber(s) or s=='true' or s=='false' or s=='pi'
end

function eval(s)
	-- optimize
	s = optimize(s)

	-- fully evaluated number
	if tonumber(s) then
		return s
	end

	-- constant
	if s=='pi' then
		return tostring(math.pi)
	end

	-- unbound var
	if type(s)=='string' then
		return s
	end
	
	-- sub
	local defined = true
	for i=2,#s do
		s[i] = eval(s[i])
		defined = defined and isdefined(s[i])
	end

	if not defined then
		return s
	end

	local args = {}
	for i=1,#s-1 do
		if tonumber(s[i+1]) then
			args[i] = tonumber(s[i+1])
		elseif s[i+1]=='true' then
			args[i] = true
		elseif s[i+1]=='false' then
			args[i] = false
		elseif s[i+1]=='pi' then
			args[i] = math.pi
		end
	end
	local succ,res = pcall(builtin[s[1]], table.unpack(args))
	if not succ then
		print(res)
		return 'undefined'
	end
	if type(res)~='table' then
		if res~=res then
			return 'undefined'
		elseif res==math.huge or res==-math.huge then
			return 'undefined'
		end
		return tostring(res)
	else
		for i,v in ipairs(res) do
			res[i] = tostring(v)
		end
	end
	return res
end

local src = [[
(and
	(= 0 (+ (* 8 (^ x 2)) (* 10 x) 2))
	(< x (| 8 6))
)
]]

-- test run! :)
print 'ORIGINEEL'
local sexpr =  parse(src)
print(unparse(sexpr))

print ''
print 'GEEVALUEERD'
print(unparse(eval(sexpr)))

