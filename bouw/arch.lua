require 'typeer'

function arch_x64(exp, types)
	local fops = set('+', '-', '*', '^', 'mod', 'abs', '/')
	local iops = set('+', '-', '*', '^', 'mod', 'abs')
	for sub in boompairs(exp) do
		local isgetal = types[sub[1]] and types[sub[1]].v == 'getal'
		local isint = types[sub[1]] and types[sub[1]]:issubtype('int')
		--if isint then print(combineer(sub) .. ' : '..e2s(types[sub[1]])..' : int') end
		if fn(sub) == 'int' then
			sub.fn = X('intd')
		--elseif types[sub.fn] and (isfn(sub.fn) or (sub.fn.exp and isfn(sub.fn.exp))) and types[sub.fn]:issubtype('->') then
			--error('ja!'..e2s(sub.fn))

			--sub.fn = X(fn(sub)..'f')
		elseif types[sub.fn] and types[sub.fn]:issubtype('lijst') then
			--error'ok'
			--sub.fn = X(fn(sub)..'f')
			--sub.fn = X'999'
			--sub.v = nil
			--sub.fn,sub[1],sub[2] = X'_', sub.fn, sub[1]
			--print('OK', e2s(sub))
			--print('ASDF', e2s(sub))
			sub[2] = sub[1]
			sub[1] = sub.fn
			sub.fn = X'_'
			--sub[1] = sub.fn
		elseif isgetal and isfn(sub) and fops[fn(sub)] then
			sub.fn = X(fn(sub)..'d')
		elseif isint and iops[fn(sub)] then
			if fn(sub) == '^' then
				--error('JA')
			end
			sub.fn = X(fn(sub)..'i')
		elseif fn(sub) == '^' then
			sub.fn = X(fn(sub)..'f')
		else
			--error('WEET NIET')
		end
	end
	return exp
end
