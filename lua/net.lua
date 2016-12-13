function client(cid, addr)
	local c = magic('%'..cid)
	c.val = {
		id = cid,
		addr = addr,
	}
	c.text = '%'..cid
	
	-- input
	local input = magic(c.name .. '.input')
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
	c.output2 = magic(c.name .. '.output')
	c.output2.last = 1
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
	end
	
	function c:close()
		close(cid, c)
		self.text = '<closing>'
	end
	return c
end

function server(port)
	local id = sas.server(port)
	if not id then
		error("bind failed")
	end
	
	local server = magic("server("..port..")")
	
	server.val = {
		id = id,
		port = port,
		cli = {}, -- magics
	}
	server.text = '%'..id
	accept(id,server)
	
	-- clients!
	local cs = magic(server.name..".cli")
	server.cli = cs
	
	cs.val = server.val.cli
	cs.text = '{}'
	triggers(server, cs)
	
	function cs:update()
		cs.text = dictstring(cs.val)
	end
	
	-- first
	cs.first = magic('cli.first')
	cs.first.text = '<none>'
	cs.first.val = nil
	function cs.first:update()
		if not self.val and next(cs.val) then
			local ref = cs.val[next(cs.val)]
			cs.first.text = ref.text
			cs.first.input = ref.input
			ref.output = cs.first.output
			getmetatable(cs.first).__newindex = getmetatable(ref).__newindex
			
			triggers(ref, cs.first)
		else
			self.val = cs.first.val
		end
	end
	triggers(cs, cs.first)
	
	-- individual !
	function server:accept(cid, addr)
		local client = client(cid, addr)	
		
		self.val.cli[cid] = client
		triggers(client, server)
	end
	return server
end