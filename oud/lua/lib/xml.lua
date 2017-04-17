function xml_find(xml, tag)
    if not xml.kids then
        return nil
    end
    for i,kid in ipairs(xml.kids) do
        if kid.tag == tag then
            return kid
        end
        local f = xml_find(kid, tag)
        if f then
            return f
        end
    end
end

function xml_find_all(xml, tag, res)
	res = res or {}
	
	if not xml.kids then
        return res
    end
    for i,kid in ipairs(xml.kids) do
        if kid.tag == tag then
            table.insert(res, kid)
        end
        xml_find_all(kid, tag, res)
    end
	return res
end

function xml_decode(fn)
	local file = open(fn)
	local curline = 1 -- current line
	 -- current fresh character
	local ch
	local done = false
	
	-- stacks
	local depth = 1
	local tags = {}
	local nodes = {[0] = xml('root')}
	local root = nodes[0]
	
	local err = error
	local function error(msg)
		local msg = msg or ''
		msg = 'xml error at '..fn..'@'..curline..': '..msg
		err(msg)
	end
	
	function iswhite()
		return ch == ' ' or ch == '\t' or ch == '\r' or ch == '\n'
	end
	
	function skipwhite(weak)
		while true do
			if not weak then
				ch = file:read(1)
			end
			weak = false
			
			if not ch then
				done = true
				return
			end
			
			-- skip white
			if iswhite() then
				if ch == '\n' then
					curline = curline + 1
				end
			else
				break
			end
		end
	end
	
	local function getchar(msg)
		ch = file:read(1) or error(msg or 'unexpected end of file')
		if ch == '\n' then
			curline = curline + 1
		end
		return ch
	end
	
	function readstring()
		local text = {}
		if ch ~= '"' and ch ~= "'" then
			error('string expected')
		end
		local delim = ch
		while true do
			ch = file:read(1) or error('unclosed string literal')
			if ch == delim then
				break
			end
			table.insert(text,ch)
		end
		-- next
		getchar()
		return table.concat(text)
	end

	getchar()
	while not done and ch do
		skipwhite(true)
		if not ch then
			break
		end
		
		if ch == '<' then
			-- comment, info, node, tag
			getchar()
			if ch == '!' then
				-- comment, info
				getchar()
				
				if ch == '-' then
					-- comment
					getchar()
					if ch == '-' then
						while true do
							-- comment
							repeat
								getchar('unclosed comment')
							until ch == '-'
							getchar('unclosed comment')
							if ch == '-' then
								::dashes::
								getchar('unclosed comment')
								if ch == '>' then
									-- done!
									ch = file:read(1) -- EOF can occur
									goto done
								elseif ch == '-' then
									goto dashes
								end
							end
						end
					end
				else
					-- info
					while true do
						getchar()
						if ch == '>' then
							getchar()
							goto done
						elseif ch == '"' then
							repeat
								getchar()
							until ch == '"'
						end
					end
				end
			elseif ch == '?' then
				-- command
				while true do
					getchar()
					if ch == '?' then
						::questionmark::
						getchar()
						if ch == '>' then
							ch = file:read(1)
							goto done
						elseif ch == '?' then
							goto questionmark
						end
					end
				end
			else
				-- tag
				skipwhite(true)
				local tag = {}
				local fin = false
				if ch == '/' then
					fin = true
					getchar()
				end
				
				-- tagname
				while not iswhite() and ch ~= '>' do
					table.insert(tag, ch)
					getchar()
				end
				
				skipwhite(true)
				
				-- attributes
				local attr = {}
				if ch ~= '>' then
					while ch ~= '>' do
						local key,val = {},nil
						skipwhite(true)
						
						-- key
						while not iswhite() and ch ~= '>' and ch ~= '=' do
							table.insert(key, ch)
							getchar()
						end
						skipwhite(true)
						-- val
						if ch == '=' then
							skipwhite()
							val = readstring()
						end
						key = table.concat(key)
						attr[key] = val or true
					end
				end
				getchar()
				
				tag = table.concat(tag)
				
				-- handle it
				if fin then
					local index
					-- find closing tag
					for i=#tags,1,-1 do
						if tags[i] == tag then
							index = i
						end
					end
					-- cleanup stack
					if index then
						for i=#tags,index,-1 do
							tags[i] = nil
							depth = depth - 1
						end
					else
						depth = depth - 1
					end
				else
					local node = xml(tag)
					for k,v in pairs(attr) do
						node[k] = v
					end
					nodes[depth-1]:add(node)
					nodes[depth] = node
					depth = depth + 1
					table.insert(tags, tag)
				end
			end
			::done::
		else
			-- text
			local text = {}
			while ch ~= '<' do
				table.insert(text, ch)
				if ch == '\n' then
					curline = curline + 1
				end
				-- TODO handle embedded strings
				ch = file:read(1) or error('unclosed text')
			end
			text = table.concat(text)
			
			nodes[depth-1]:add(text)
		end
	end
	
	-- clean
	if #root.kids == 1 then
		return root.kids[1]
	else
		return root
	end
end

function xml_encode(node, parts)
	parts = parts or {}
	if type(node) == 'string' then
		table.insert(parts, node)
		return
	end
	
	table.insert(parts, "<")
	table.insert(parts, node.tag)
	
	for k,v in pairs(node) do
		if k:sub(1,1) ~= '_' then
			if type(k) == 'string' and type(v) == 'string' then
				table.insert(parts, " ")
				table.insert(parts, k)
				table.insert(parts, "=")
				table.insert(parts, string.format("%q",v))
			elseif type(k) == 'string' and v == true then
				table.insert(parts, " ")
				table.insert(parts, k)
			elseif type(k) == 'string' and type(v) == 'function' and k:sub(1,2) == 'on' then
				table.insert(parts, " ")
				table.insert(parts, k)
				table.insert(parts, "=")
				table.insert(parts, [['notify(]])
				table.insert(parts, string.format("%q", node.id))
				table.insert(parts, [[, document.getElementById(]])
				table.insert(parts, string.format("%q", node.id))
				table.insert(parts, [[).value]])
				table.insert(parts, [[)']])
			end
		end
	end
	
	--if not node._text and (not node.kids or #node.kids == 0) then
	--	table.insert(parts, "/>")
	--else
		table.insert(parts, ">")
	--end
	
	if node.kids then
		for i,v in ipairs(node.kids) do
			xml_encode(v, parts)
		end
	end
	
	--if node._text or node.kids then
		table.insert(parts, node._text)
		
		table.insert(parts, "</")
		table.insert(parts, node.tag)
		table.insert(parts, ">\r\n")
	--end
end

local node = {}
	
function node:add(sub)
	if not self.kids then
		self.kids = {}
	end
	table.insert(self.kids, sub)
end

function node:encode()
	local parts = {}
	xml_encode(self, parts)
	return table.concat(parts)
end

function node:encoderoot()
	local parts = {}
	for i,child in ipairs(self.kids) do
		xml_encode(self,parts)
	end
	return table.concat(parts)
end

function xml(tag, text)
	local mt = {__index = node}
	local node = {}
	setmetatable(node, mt)
	
	node.tag = tag
	
	if text then
		node:add(text)
	end
	
	return node
end