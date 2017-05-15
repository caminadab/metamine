function substitute(sexp, dst, src)
	if atom(sexp) then
		if sexp==src then
			return dst
		else
			return sexp
		end
	else
		local res = {}
		for i=1,#sexp do
			res[i] = substitute(sexp[i], dst, src)
		end
		return res
	end
end

-- (a:=3 b:=a+a) oplosser
-- nu met subtypes ;4
function simplesolve(sexp)
	-- substitute
	for _,eq in ipairs(sexp) do
		local src,dst = eq[2],eq[3]

		-- enkele variabele
		if atom(src) then
			for i,eq in ipairs(sexp) do
				eq[3] = substitute(eq[3], dst, src)
			end
		else
			-- strekking variabele
			local scope = src[2]
			for i,eq in ipairs(sexp) do
				if eq[2]==scope then
					eq[3] = substitute(eq[3], dst, src[3])
				end
			end
		end
	end
	
	-- evaluate
	for _,eq in ipairs(sexp) do
		eq[3] = eval(eq[3])
	end
	
	return sexp
end
	
function eval(sexp)
	-- zijn het ass?
	if exp(sexp) and head(sexp[1])==':=' then
		return simplesolve(sexp)
	end
	
	-- getal
	if tonumber(sexp) then return sexp end
	
	-- eerst subs oplossen!
	if exp(sexp) then
		for i,arg in ipairs(sexp) do
			sexp[i] = eval(sexp[i])
		end
	end
	
	-- standaard
	if builtin[head(sexp)] then
		-- subs
		local args = tail(sexp)
		if #args==1 and exp(args[1]) then
			args = args[1]
		end
		
		-- nu laat ons gaan
		local builtin = builtin[head(sexp)]
		local ok,res = pcall(builtin, table.unpack(args))
		if ok then
			return tostring(res)
		else
			return sexp
		end
	end
	
	return sexp
end