require 'lib'
require 'unicode'

local postop = set("%","!",".","'")
local binop  = set("+","·","/","^","∨","∧","×","..","→","∘","_","⇒",">","≥","=","≠","≈","≤","<",":=","+=","|=","|:=", "∪","∩",":","∈","‖","\\", "^f","_f","index", "+f","+f1","·f","·f1","+v1","call1","^l")
local unop   = set("-","#","¬","Σ","|","⋀","⋁","√","|")

function lenc2(exp)
	if type(exp) == 'table' and (isatom(exp) or isobj(exp) or isfn(exp)) then
		return unlisp(exp)
	else
		return lenc(exp)
	end
end

-- sfc, oudi  →  proc, nieuwi
function readfn(sfc, i)
	local proc = {o=X'[]'}
	local diepte = 0

	while true do
		--print('PROC', i, diepte, deparse(sfc[i]))
		proc[#proc+1] = sfc[i]

		if atom(sfc[i]) == 'eind' and diepte == 0 then
			return proc, i
		end
		if i > #sfc then
			error('onafgesloten functie')
		end
		if fn(sfc[i]) == 'fn' then
			diepte = diepte + 1
		end
		if atom(sfc[i]) == 'eind' then
			diepte = diepte - 1
		end

		i = i + 1
	end
end

-- sfc → func
function doe(sfc, stack, arg0, arg1, arg2, arg3)
	local stack = stack or {}
	local i = 1
	local lib = lib()
	local cache = {}

	while i <= #sfc do
		local ins = sfc[i]

		if atom(ins) == 'call' then
			local a = stack[#stack-1]
			local b = stack[#stack-0]
			local r = a(b)
			stack[#stack] = nil
			stack[#stack] = r

		elseif atom(ins) == 'call2' then
			local f = stack[#stack-2]
			local a = stack[#stack-1]
			local b = stack[#stack-0]
			local r = f(a, b)
			stack[#stack] = nil
			stack[#stack] = nil
			stack[#stack] = r

		elseif atom(ins) == 'call3' then
			local f = stack[#stack-3]
			local a = stack[#stack-2]
			local b = stack[#stack-1]
			local c = stack[#stack-0]
			local r = f(a, b, c)
			stack[#stack] = nil
			stack[#stack] = nil
			stack[#stack] = nil
			stack[#stack] = r

		elseif atom(ins) == 'call4' then
			local f = stack[#stack-4]
			local a = stack[#stack-3]
			local b = stack[#stack-2]
			local c = stack[#stack-1]
			local d = stack[#stack-0]
			local r = f(a, b, c, d)
			stack[#stack] = nil
			stack[#stack] = nil
			stack[#stack] = nil
			stack[#stack] = nil
			stack[#stack] = r

		elseif atom(ins) == 'niets' then
			stack[#stack+1] = 0

		elseif atom(ins) == 'lus' then
			-- niets

		-- cache STORE
		elseif fn(ins) == 'st' then
			local index = tonumber(atom(arg(ins)))
			cache[index] = stack[#stack]
			--print('cache store', index, lenc(stack[#stack]))

		-- cache RETRIEVE
		elseif fn(ins) == 'ld' then
			local index = tonumber(atom(arg(ins)))
			stack[#stack+1] = assert(cache[index], index.." zit niet in de cache")
			--print('cache load', index, lenc(stack[#stack]))

		elseif atom(ins) == '_l' then
			local a = stack[#stack-1]
			local b = stack[#stack-0]
			local r = a[b+1]
			stack[#stack] = nil
			stack[#stack] = r

		elseif atom(ins) == 'eind' then
			local res = stack[#stack]
			stack[#stack] = nil
			return res

		elseif fn(ins) == 'kp' then
			local index = tonumber(atom(arg(ins)))
			stack[#stack+1] = stack[#stack-index]

		elseif fn(ins) == 'arg' then
			stack[#stack+1] = arg0

		elseif fn(ins) == 'arg0' then
			stack[#stack+1] = arg0
		elseif fn(ins) == 'arg1' then
			stack[#stack+1] = arg1
		elseif fn(ins) == 'arg2' then
			stack[#stack+1] = arg2
		elseif fn(ins) == 'arg3' then
			stack[#stack+1] = arg3

		elseif fn(ins) == 'string' then
			local num = atom(arg(ins))
			local r = {}
			for i=1,num do
				local top = stack[#stack]
				r[num-i+1] = utf8encode(top)
				stack[#stack] = nil
			end
			stack[#stack+1] = table.concat(r)


		elseif fn(ins) == 'lijst' or fn(ins) == 'tupel' then
			local num = atom(arg(ins))
			local r = {}
			for i=num,1,-1 do
				r[i] = stack[#stack]
				stack[#stack] = nil
			end
			stack[#stack+1] = r

		elseif fn(ins) == 'set' then
			local num = atom(arg(ins))
			local r = {}
			for i=1,num do
				local top = stack[#stack]
				r[top] = true
				stack[#stack] = nil
			end
			stack[#stack+1] = r

		elseif atom(ins) == 'dan' then
			if stack[#stack] == false then
				-- skip tot 'einddan'
				while atom(ins) ~= 'einddan' and atom(ins) ~= 'anders' do
					i=i+1
					ins = sfc[i]
				end
				stack[#stack] = false
			end

		elseif atom(ins) == 'anders' then
			if stack[#stack] ~= false then
				-- skip tot 'einddan'
				while atom(ins) ~= 'einddan' do
					i=i+1
					ins = sfc[i]
				end
				stack[#stack] = false
			end

		elseif binop[atom(ins)] then
			local f = atom(ins)
			local a = stack[#stack-1]
			local b = stack[#stack]
			stack[#stack] = nil
			stack[#stack] = lib[f](a, b)

		elseif unop[atom(ins)] then
			local f = atom(ins)
			local a = stack[#stack]
			stack[#stack] = lib[f](a)

		elseif lib[atom(ins)] then
			stack[#stack+1] = lib[atom(ins)]

		elseif atom(ins) == 'einddan' then
			-- niets
			stack[#stack-1] = stack[#stack]
			stack[#stack] = nil

		elseif fn(ins) == 'fn' then
			local proc
			i = i + 1
			proc,i = readfn(sfc, i)

			stack[#stack+1] = function(...) return doe(proc, stack, ...) end
			
		elseif tonumber(atom(ins)) then
			stack[#stack+1] = tonumber(atom(ins))

		elseif atom(ins) == '⊤' then
			stack[#stack+1] = true

		elseif atom(ins) == '⊥' then
			stack[#stack+1] = false

		elseif atom(ins) == 'dup' then
			stack[#stack+1] = stack[#stack]

		elseif atom(ins) == 'vierkant' then
			--sdl2.renderfillrect
			local x = stack[#stack]
			stack[#stack] = nil
			print("X", x)
			local y = stack[#stack]
			print("Y", y)
			stack[#stack] = nil
			local r = stack[#stack]
			print("R", r)
			stack[#stack] = function(args)
				return "vierkant("..x..","..y..","..r..")"
			end

		else
			error('weet niet hoe te doen: '..deparse(ins))
		end

		if opt and opt.L then
			io.write(unlisp(ins) .. '\t| ')
		
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
