require 'exp'
require 'bieb'

function w2exp(w)
	local uit
	if w == true then
		uit = X'ja'
	elseif w == false then
		uit = X'nee'
	elseif type(w) == 'function' then
		uit = X'functie'
	elseif tonumber(w) then
		uit = X(tostring(w))
	elseif type(w) == 'table' then
		if w.isset then
			uit = X('{}', table.unpack(map(w, w2exp)))
		else
			uit = X('[]', table.unpack(map(w, w2exp)))
		end
	else
		return X(w)
		--error(w..type(w)	)
	end
	uit.w = w
	return uit
end

local dynamisch = {
	aselect = true
}

function optimaliseer(exp)
	function w(e, ...)
		if isatoom(e) then
			if tonumber(e.v) then
				e.w = tonumber(e.v)
			elseif bieb[e.v] and not dynamisch[e.v] then
				e.w = bieb[e.v]
			elseif e.v == '_arg0' then
				e.w = ...
			else
				print('onbekend: '..e.v)
			end
			return e
		end
		if isfn(e) then
			if fn(e) == '_fn' then
				print('SUBST', 'arg', exp2string(e[2]))

				-- is helemaal goed?
				
				--[[
				local ok = true
				for node in boompairs(f) do
					if not node.w and node.v ~= '_arg0' then
						ok = false
						error(exp2string(node))
						break
					end
				end
				--]]

				local D = function (w)
					local ok, res = pcall(
						function()
							return optimaliseer(substitueer(e[1], X('_arg', e[2]), w2exp(w))).w
						end
					)
					assert(ok)
					return res or nil
				end

				e.w = D

				return e
			end

			local ok = (e.fn.w ~= nil)
			local func = e.fn.w
			local args = {}
			for i,arg in ipairs(e) do
				ok = ok and arg.w ~= nil
				args[i] = arg.w
			end
			--print('OK?', ok)
			--print(e.fn.w, table.unpack(args))

			if ok then
				local ok,w = pcall(func,table.unpack(args))
				--print('OPT', exp2string(e), ' = ', combineer(w2exp(w)))

				if ok then
					return w2exp(w)
				else
					w = e
					return e
				end

				return ok and w2exp(w) or e
			end

			-- niet optimaliseerbaar...
			return e
		elseif e.w then
			return w2exp(w)
		else
			return e
		end

	end

	for node in boompairsdfs(exp) do
		if isfn(node) then
			node.fn = w(node.fn)
			for i=1,#node do
				node[i] = w(node[i])
			end
		end
	end
	exp = w(exp)
	--exp = emap(exp, w)
	--exp = w(exp)

	if verbozeWaarde then
		print(exp2string(exp))
	end

	return exp
end

if true or test then
	require 'ontleed'
	require 'combineer'

	local function T(x)
		return combineer(optimaliseer(ontleedexp(x)))
	end

	local a = T "(((1 + 1) + 1) + 1)"
	assert(a == "4", a)

	local a = T "2 + 3"
	assert(a == "5", a)

	local a = T "2 max 1"
	assert(a == "2", a)

	local a = T "(1 + 1) + (1 + 1)"
	assert(a == "4", a)

	local a = T "((1 + 1) + 1)"
	assert(a == "3", a)

	local a = T "((((1 + 1) + 1) + 1) + 1)"
	assert(a == "5", a)

	local a = T "1 + 1 + 1 + 1"
	assert(a == "4", a)
end
