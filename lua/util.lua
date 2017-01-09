function see(tt)
	for k,v in pairs(tt) do
		print(k,v)
	end
end

function first(tt)
	return tt[next(tt)]
end