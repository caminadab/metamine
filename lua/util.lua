function see(tt)
	for k,v in pairs(tt) do
		print(k,v)
	end
end

function first(tt)
	return tt[next(tt)]
end

function set2text(set)
	local tt = { '(' }
	for item in pairs(set) do
		table.insert(tt, item)
		if next(set, client) then
			table.insert(tt, ' ')
		end
	end
	table.insert(tt, ')')
	
	return table.concat(tt)
end

function dict2text(dict)
	self.val = {}
	local tt = {'{'}
	for client in pairs(clients.val) do
		self.val[client] = client.input
		table.insert(tt, client.name)
		table.insert(tt, ' -> ')
		table.insert(tt, (encode(client.input)))
		
		if next(clients.val, client) then
			table.insert(tt, '  ')
		end
	end
	table.insert(tt, '}')
	self.text = table.concat(tt)
end