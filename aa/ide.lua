-- hex
function hex_encode(txt)
	local res = {}
	for i=1,#txt do
		table.insert(res, string.format("%02x", string.byte(txt:sub(i,i))))
	end
	return table.concat(res)
end

function hex_decode(hex)
	local res = {}
	for i=1,#hex-1,2 do
		local sub = hex:sub(i,i+1)
		local num = tonumber(sub, 16)
		table.insert(res, string.char(num))
	end
	return table.concat(res)
end

-- file library
function open(path)
	local file = {}
	file.path = path
	file.cur = 1
	-- write => table, read => string
	file.data = nil
	
	function file:read(n)
		if not file.data then
			file.data = read(self.path) or read('/'..self.path) or error('could not read')
		end
		if file.cur >= #file.data then
			return nil
		end
		local res = self.data:sub(self.cur, self.cur + n - 1)
		if not res or #res == 0 then
			return nil
		end
		self.cur = self.cur + n
		return res
	end
	
	function file:write(res)
		if not file.data then
			file.data = {}
		end
		table.insert(file.data, res)
	end
	
	function file:close()
		if type(file.data) == 'table' then
			write(file.path, table.concat(file.data))
		end
	end
	
	return file
end

local term = js.global.document:getElementById('out')
function print(...)
	local args = {...}
	for i=1,#args do
		args[i] = tostring(args[i])
	end
	local text = table.concat(args, '\t')
	term.innerHTML = term.innerHTML .. text .. '<br>'
	term.scrollTop = 99999
end

function read(name)
	return js.global:read('/'..name)
end

function write(name, data)
	js.global:write('/'..name, data)
	js.global:fill(js.global.document:getElementById('tree'))
end

local reg = debug.getregistry()
function require(name)
	if reg._LOADED[name] then
		return
	end
	reg._LOADED[name] = true
	local path = name..'.lua'
	local file = read(path)
	if file then
		local chunk,err = load(file)
		if not chunk then
			reg._LOADED[name] = 'error'
			print(path..' '..err)
		else
			reg._LOADED[name] = chunk
			return chunk()
		end
	else
		return req(name)
	end
end