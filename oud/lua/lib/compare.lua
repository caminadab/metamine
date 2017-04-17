

-- compare
function compare(a,b,key,tt)
	tt = tt or {}
	
	-- meat
	if type(a) == 'table' and type(b) == 'table' then
		for k,v in pairs(a) do
			
			-- else compare
			compare(a[k], b[k], k, tt)
		end
		
		for k,v in pairs(b) do
			
			-- else compare
			compare(a[k], b[k], k, tt)
		end
	else
		if a ~= b then
			if (a == 0 and not b) or (b == 0 and not a) then
				-- nothing
			else
				table.insert(tt, '['..key..']; a='..tostring(a)..',b='..tostring(b))
			end
		end
	end
		
	return tt
end