require 'typeer'

function arch_x64(exp, types)
	local fops = set('+', '-', '*', '^', 'mod', 'abs', '/')
	local iops = set('+', '-', '*', '^', 'mod', 'abs')
	for sub in boompairs(exp) do
		local isgetal = types[sub] and types[sub].v == 'getal'
		local isint = types[sub] and types[sub].v == 'int'
		if fn(sub) == 'int' then
			sub.fn = X('intd')
		elseif types[sub.fn] and types[sub.fn]:issubtype('->') then
			--error'ok'
			--sub.fn = X(fn(sub)..'f')
		elseif types[sub.fn] and types[sub.fn]:issubtype('lijst') then
			--error'ok'
			--sub.fn = X(fn(sub)..'f')
		elseif isgetal and isfn(sub) and fops[fn(sub)] then
			sub.fn = X(fn(sub)..'d')
		elseif isint and isfn(sub) and iops[fn(sub)] then
			sub.fn = X(fn(sub)..'i')
		elseif fn(sub) == '^' then
			sub.fn = X(fn(sub)..'f')
		else
			--error('WEET NIET')
		end
	end
	return exp
end
