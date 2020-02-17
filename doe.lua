require 'bieb'

local postop = set("%","!",".","'")
local binop  = set("+","·","/","^","∨","∧","×","..","→","∘","_","⇒",">","≥","=","≠","≈","≤","<",":=","+=","|=","|:=", "∪","∩",":","∈","‖")
local unop   = set("-","#","¬","Σ","|","⋀","⋁","√","|")

function lenc2(exp)
	if type(exp) == 'table' and (isatoom(exp) or isobj(exp) or isfn(exp)) then
		return unlisp(exp)
	else
		return lenc(exp)
	end
end

-- sfc → func
function doe(sfc, arg0)
	local stack = {}
	local i = 1
	local bieb = bieb()

	while i <= #sfc do
		local ins = sfc[i]

		if atoom(ins) == '_f' then
			local a = stack[#stack-1]
			local b = stack[#stack-0]
			local r = a(b)
			stack[#stack] = nil
			stack[#stack] = r

		elseif atoom(ins) == '_l' then
			local a = stack[#stack-1]
			local b = stack[#stack-0]
			local r = a[b+1]
			stack[#stack] = nil
			stack[#stack] = r

		elseif atoom(ins) == 'eind' then
			return stack[#stack]

		elseif fn(ins) == 'arg' then
			stack[#stack+1] = arg0

		elseif binop[atoom(ins)] then
			local f = atoom(ins)
			local a = stack[#stack]
			local b = stack[#stack-1]
			local args = {a, b}
			stack[#stack] = nil
			stack[#stack] = bieb[f](args)

		elseif fn(ins) == 'fn' then
			local proc = {o='[]'}
			local ins0 = ins

			while atoom(ins) ~= 'eind' do
				i=i+1
				ins = sfc[i]
				proc[#proc+1] = ins
			end
			stack[#stack+1] = function(x) return doe(proc, x) end
			
			--[[io.write('fn('..atoom(arg(ins0)), '): ')
			for i,v in ipairs(proc) do
				io.write(unlisp(v),' ')
			end
			print()
			]]

		elseif tonumber(atoom(ins)) then
			stack[#stack+1] = tonumber(atoom(ins))

		else
			error('weet niet hoe te doen: '..combineer(ins))
		end

		if opt and opt.L then
			io.write(combineer(ins) .. '\t| ')
		
			for i, v in ipairs(stack) do
				io.write(lenc2(v), ' ')
			end
			io.write('\n')
		end

		i = i + 1
	end

	--print("RET", lenc(stack[#stack]))
	return stack[#stack]
end
