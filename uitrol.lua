require 'symbool'
require 'typeer'

function subst(exp, van, naar)
	if isatoom(exp) then
		if exp == van then
			return naar
		else
			return exp
		end
	else
		local r = {}
		for i=1,#exp do
			r[i] = subst(exp[i],van,naar)
		end
		return r
	end
end

function uitrol(stroom, typen)
	local r = {}
	local uitgerold = {} -- naam -> uitrol?
	for i,v in ipairs(stroom) do
		local naam,val = v[2],v[3]
		local t = typen[naam]

		if isexp(t) and t[1] == '^' and tonumber(t[3]) then
			local n = tonumber(t[3])
			local fn = val[1]
			local tfn = typen[fn]
			local doeltype = typen[naam]

			if isexp(val) then
				print(naam,n,leed(tfn),leed(doeltype))
			end

			-- array unpacking
			if isexp(val) and val[1] == '[]' then
				uitgerold[naam] = true
				for i=2,#val do
					local naam = naam..(i-2)
					r[#r+1] = {'=', naam, val[i]}
				end

			-- kleine loopjes
			elseif tfn and isexp(val) and
					isatoom(tfn[2]) and isatoom(tfn[3]) then
				for i=1,n do
					local val = kopie(val)
					local index = tostring(i-1)
					-- doorloop bronnen, fix ariteit
					for bron in pairs(var(val)) do
						local len = lijstlen(typen[bron])
						uitgerold[naam] = len
						if len then
							local doel
							if uitgerold[bron] then
								doel = bron..index
							else
								doel = {bron, index}
							end
							val = subst(val,bron,doel)
						end
					end
					local naam = naam .. (i-1)
					r[#r+1] = {'=', naam, val}
				end
			else
				r[#r+1] = v
			end
		else
			r[#r+1] = v
		end
	end

	-- laatste maken
	local doel = stroom[#stroom][2]
	print('DOEL',doel)
	for n,v in pairs(uitgerold) do print(n,v) end
	print('dat')
	if uitgerold[doel] then
		-- inrollen
		local a = {'[]'}
		for i=1,uitgerold[doel] do
			local index = tostring(i-1)
			a[#a+1] = doel..index
		end
		r[#r+1] = {'=', doel, a}
	end
	--if stroom[#stroom]
	return r
end
			
