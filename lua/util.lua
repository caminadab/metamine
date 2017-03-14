function first(tt)
	return tt[next(tt)]
end

function table_print (tt, indent, done)
  done = done or {}
  indent = indent or 0
  if type(tt) == "table" then
    local sb = {}
    for key, value in pairs (tt) do
      table.insert(sb, string.rep (" ", indent)) -- indent it
      if type (value) == "table" and not done [value] then
        done [value] = true
		table.insert(sb, tostring(key).." = ")
        table.insert(sb, "{\n");
        table.insert(sb, table_print (value, indent + 2, done))
        table.insert(sb, string.rep (" ", indent)) -- indent it
        table.insert(sb, "}\n");
      elseif "number" == type(key) then
        table.insert(sb, string.format("\"%s\"\n", tostring(value)))
      else
        table.insert(sb, string.format(
            "%s = \"%s\"\n", tostring (key), tostring(value)))
       end
    end
    return table.concat(sb)
  else
    return tt .. "\n"
  end
end

function to_string( tbl )
    if  "nil"       == type( tbl ) then
        return tostring(nil)
    elseif  "table" == type( tbl ) then
        return table_print(tbl)
    elseif  "string" == type( tbl ) then
        return tbl
    else
        return tostring(tbl)
    end
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

function deepget(t,keys)
	local c = t
	
	for i=1,#keys do
		local key = keys[i]
		if c[key] == nil then
			return nil
		end
		c = c[key]
	end
	
	return c
end

function deepset(t,keys,v)
	local c = t
	
	-- create tables
	for i=1,#keys-1 do
		local key = keys[i]
		c[key] = c[key] or {}
		c = c[key]
	end
	c[keys[#keys]] = v
end
