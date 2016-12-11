function client(cid, addr)
	local c = magic('#'..cid)
	c.val = {
		id = cid,
		addr = addr,
		input = '',
	}
	
	-- input
	local input = magic(c.name .. '.input')
	input.val = ''
	input.text = '<empty>'
	function input:update()
		self.val = c.val.input
		self.text = encode(self.val)
	end
	c.input = input
	triggers(c, input)
	
	-- events
	--triggers(, name)
	read(cid,c)
	function c:read(data)
		self.val.input = self.val.input .. data
		self.text = encode(self.val.input)
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
	server.text = '#'..id
	--triggers(, server)
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
			self.val = cs.val[next(cs.val)]
			self.text = self.val.text
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