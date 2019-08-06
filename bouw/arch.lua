require 'typeer'

arch = {}

function arch.x64(exp, types)
	local fops = set('+', '-', '*', '^', 'mod', 'abs', '/')
	local iops = set('+', '-', '*', '^', 'mod', 'abs')
	for sub in boompairs(exp) do
		local arg = sub[1]
		local isgetal = types[arg] and types[arg].v == 'getal'
		local isint = types[arg] and types[arg]:issubtype('int')
		if fn(sub) == 'int' then
			sub.fn = X('intd')
		elseif types[sub.fn] and types[sub.fn]:issubtype('lijst') then
			sub[2] = sub[1]
			sub[1] = sub.fn
			sub.fn = X'_'
		elseif isgetal and isfn(sub) and fops[fn(sub)] then
			sub.fn = X(fn(sub)..'d')
		elseif isint and iops[fn(sub)] then
			sub.fn = X(fn(sub)..'i')
		elseif fn(sub) == '^' then
			sub.fn = X(fn(sub)..'f')
		end
	end
	return exp
end

function arch.js(exp, types)
	for sub in boompairs(exp) do
		local type = types[sub]
		if type then
			if fn(sub) == '[]' then
				if type:issubtype('tekst') then
					sub.fn = X('[]u')
				end
			end
		end
		local a,b = sub[1],sub[2]

		local isgetal = types[sub[1]] and types[sub[1]].v == 'getal'
		local isint = types[sub[1]] and types[sub[1]]:issubtype('int')
		if fn(sub) == 'int' then
			sub.fn = X('intd')
		--elseif types[sub.fn] and types[sub.fn]:issubtype('[]u') then
			--sub.fn = X('tekst')
		elseif fn(sub) == '||' and types[sub] and types[sub]:issubtype('tekst') then
			sub.fn = X('||u')
		elseif fn(sub) == '||' and types[a] and types[b] and types[a]:issubtype('tekst') and types[a]:issubtype('tekst') then
			sub.fn = X('||u')
		elseif fn(sub) == 'cat' and types[a] and types[b] and types[a]:issubtype('tekst') and types[b]:issubtype('tekst') then
			sub.fn = X('catu')
		elseif fn(sub) == 'map' and types[a] and types[b] and types[exp] and types[a]:issubtype('tekst') and types[b]:issubtype('tekst') and types[exp]:issubtype('tekst') then
			sub.fn = X('mapuu')

		-- index
		elseif types[sub.fn] and types[sub.fn]:paramtype('int').v == 'teken' then
			error'OK!'
			sub[2] = sub[1]
			sub[1] = sub.fn
			sub.fn = X'_u'
		--[[
		elseif types[sub.fn] and types[sub.fn]:issubtype('lijst') then
			sub[2] = sub[1]
			sub[1] = sub.fn
			sub.fn = X'_'
		]]
		elseif fn(sub) == '^' then
			sub.fn = X(fn(sub)..'f')
		end
	end
	return exp
end

arch.ifunc = arch.js
arch.demo = arch.js
