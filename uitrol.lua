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

function issimpel(t)
	if isatoom(t) then return true
	elseif t[1] ~= ',' then return false
	else
		for i=2,#t do
			if type(t[i]) ~= 'string' then
				return false
			end
		end
		return true
	end
end

function uitrol(stroom, typen)
	local r = {}
	local uitgerold = {} -- naam -> uitrol?
	for i,v in ipairs(stroom) do
		local naam,val = v[2],v[3]
		local t = typen[naam]

		if lijstlen(t) then
			local n = tonumber(t[3])
			local fn = val[1]
			local tfn = typen[fn]
			local doeltype = typen[naam]

			if isexp(val) then
				--print('UITROL',naam..'^'..n,leed(tfn),leed(doeltype))
			end

			-- lijst
			if isexp(val) and val[1] == '[]' then
				--[[
				-- uitgerold
				uitgerold[naam] = #val-1
				local stam = naam
				for i=2,#val do
					local naam = stam..''..(i-2)
					r[#r+1] = {'=', naam, val[i]}
				end
				]]
				r[#r+1] = {'=', naam, val}

			-- kleine loopjes
			-- TODO te strak gematcht
			elseif tfn and isexp(val) and
					issimpel(tfn[2]) and isatoom(tfn[3]) then
					print('ROL')
				
				-- uitgerolde loop
				for i=1,n do
					local naam = naam..'_'..(i-1)
					local val = kopie(val)
					local index = tostring(i-1)
					-- doorloop bronnen, fix ariteit
					for bron in spairs(var(val)) do
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
					--local naam = naam .. '_'..(i-1)
					r[#r+1] = {'=', naam, val}
				end

				-- normale loop
				for i=1,n do
					local naam = naam..'_'..(i-1)
					local val = kopie(val)
					local index = tostring(i-1)
					-- doorloop bronnen, fix ariteit
					for bron in spairs(var(val)) do
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
					--local naam = naam .. '_'..(i-1)
					r[#r+1] = {'=', naam, val}
				end

				-- collect
				local l = {'[]'}
				for i=1,n do
					l[#l+1] = tostring(naam)..'_'..(i-1)
				end
				r[#r+1] = {'=', naam, l}

			else
				print('EMIT normale loop')
				r[#r+1] = v
			end
		else
			r[#r+1] = v
		end
	end

	-- laatste maken
	local doel = stroom[#stroom][2]
	for n,v in spairs(uitgerold) do print(n,v) end
	if uitgerold[doel] then
		-- inrollen
		local a = {'[]'}
		print(uitgerold[doel])
		for i=1,uitgerold[doel] do
			local index = tostring(i-1)
			a[#a+1] = doel..index
		end
		r[#r+1] = {'=', doel, a}
	end
	--if stroom[#stroom]
	return r
end
			
