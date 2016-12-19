function client(clients, cid, addr)
	local c = magic('%'..cid)
	c.text = '%'..cid
	c.group = 'client'
	c.val = {
		id = cid,
		addr = addr,
	}
	
	-- events
	read(cid, c)
	function c:read(data)
		--self.val = self.val .. data
		--self.text = encode(self.val)
	end
	
	-- input
	--[[local input = magic(c.name .. '.input')
	c.input = input
	input.val = ''
	input.text = '<empty>'
	function input:update()
		self.text = encode(self.val)
	end
	
	triggers(input, c)
	
	-- output
	c.output2 = magic('output')
	c.output2.last = 1
	c.output2.text = '<empty>'
	c.output2.val = ''
	function c.output2:update()
		if self.val and self.val.val then
			local data = self.val.val
			if #data >= self.last then
				local todo = data:sub(self.last)
				write(c.val.id, c.output2, todo)
			end
		end
	end
	
	function c.output2:write(len)
		self.last = self.last + len
		
		-- are we done sending?
		if self.last > #self.val then
			write2data[c.val.id] = nil
			write2magic[c.val.id] = nil
		end
	end
	
	getmetatable(c).__newindex = function (t,key,any)
		if key == 'output' then
			c.output2.val = enchant(any)
			triggers(c.output2.val, c.output2)
		else
			rawset(t,key,any)
		end
	end]]
	
	function c:close()
		close(cid, self)
		self.text = '<closing>'
		clients:close(self)
	end
	return c
end

local servers = {}

function server(port)
	if servers[port] then
		return servers[port]
	end
	
	local id = sas.server(port)
	if not id then
		error("bind failed")
	end
	
	local server = magic()
	server.text = '%'..id..' p'..port
	server.group = 'server'
	server.val = {
		id = id,
		port = port,
	}
	
	-- clients!
	local clients = magic()
	server.clients = clients
	clients.group = '(client)'
	clients.val = {}
	clients.name = 'clients'
	clients.text = '()'
	accept(id,clients)
	
	function clients:update()
		local tt = { '(' }
		for client in pairs(self.val) do
			table.insert(tt, client.text)
			if next(self.val, client) then
				table.insert(tt, ' ')
			end
		end
		table.insert(tt, ')')
		
		self.text = table.concat(tt)
	end
	
	function clients:close(client)
		self.val[client] = nil
	end
	
	function clients:accept(cid, addr)
		local client = client(self, cid, addr)
		
		self.val[client] = true
		triggers(client, self)
	end
	servers[port] = server
	return server
end