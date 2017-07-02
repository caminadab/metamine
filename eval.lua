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
function evalLabel(sexp)
	-- substitute
	for _,eq in ipairs(sexp) do
		local src,dst = eq[2],eq[3]

		-- enkele variabele
		if atom(src) then
			for i,eq in ipairs(sexp) do
				eq[3] = substitute(eq[3], dst, src)
			end
		else
			eq[3] = 'error'
		end
	end
	
	-- evaluate
	for _,eq in ipairs(sexp) do
		if eq[1]~='=' then
			eq[3] = eval(eq[3])
		end
	end
	
	return sexp
end
	
function tolua(atom)
	if atom:sub(1,1)=="'" then
		return atom:sub(2,-2)
	elseif tonumber(atom) then
		return tonumber(atom)
	else
		return true
	end
end

function tolisp(o)
	if type(o)=='string' then
		return "'"..o.."'"
	elseif type(o)=='number' then
		return tostring(o)
	else
		return o
	end
end

function evalTest(sexp)
	
end

function eval(sexp)
	sexp = evalTest(sexp)
	sexp = evalLabel(sexp)
	sexp = evalPure(sexp)
end

function evalLabel(sexp)
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
		
		-- maak parameters
		local newargs = {}
		for i,arg in ipairs(args) do
			if atom(arg) then
				newargs[i] = tolua(arg)
			else
				newargs[i] = true
			end
		end
		
		-- nu laat ons gaan
		local builtin = builtin[head(sexp)]
		local ok,res = pcall(builtin, table.unpack(newargs))
		if ok then
			return tolisp(res)
		else
			return sexp
		end
	end
	
	return sexp
end
