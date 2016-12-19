function client(cid, addr)
	local c = magic('%'..cid)
	c.text = '%'..cid
	c.group = 'client'
	c.val = {
		id = cid,
		addr = addr,
	}
	
	-- input
	--[[local input = magic(c.name .. '.input')
	c.input = input
	input.val = ''
	input.text = '<empty>'
	function input:update()
		self.text = encode(self.val)
	end
	
	-- events
	read(cid, input)
	function input:read(data)
		self.val = self.val .. data
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
		close(cid, c)
		self.text = '<closing>'
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
	accept(id,server)
	
	-- clients!
	local clients = magic()
	server.clients = clients
	clients.group = '(client)'
	clients.val = {}
	clients.name = 'clients'
	clients.text = '()'
	triggers(server, clients)
	
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
	
	-- individual !
	function server:accept(cid, addr)
		local client = client(cid, addr)
		
		self.clients.val[client] = client
		triggers(client, server)
	end
	servers[port] = server
	return server
end