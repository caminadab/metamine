function isfn(exp)
	return type(exp) == 'table' and exp.fn
end
function isatoom(exp)
	return type(exp) == 'string'
end

function maakfn(naam,...)
	local exp
	if type(naam) == 'table' then
		exp = naam
	else
		exp = { fn = naam, ... }
	end

	setmetatable(exp, {
		__tostring = function(zelf)
			local params = {}
			for k,param in pairs(zelf) do
				params[k] = tostring(param)
			end
			return params.fn..'('..table.concat(params,',')..')'
		end
	})
	return exp
end

function maakeq(l,r)
	local eq = {type='eq',fn='=',l,r}
	setmetatable(eq, {
		__tostring = function(zelf)
			return tostring(zelf[1])..' = '..tostring(zelf[2])
		end;
		__eq = function(zelf,ander)
			if isatoom(zelf) ~= isatoom(ander) then return false end
			if isatoom(zelf) then return zelf == ander end
			if zelf.fn ~= ander.fn then return false end
			if #zelf ~= #ander then return false end
			for i=1,#zelf do
				if zelf[i] ~= ander[i] then
					return false
				end
			end
			return true
		end;
	})
	return eq
end
