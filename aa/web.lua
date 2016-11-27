#!/usr/bin/lua
require 'json'
require 'markdown'
require 'util'
require 'xml'

local first = io.read("*line")
if not first then
--break
end

local how,what,with = first:match("(%S+) (%S+) (%S+).")
while true do
	local line = io.read("*line")
	if #line <= 1 then
		break
	end
end

local res,err

-- path
local what2,query2 = what:match("([^?]+)(%?.+)$") 
if what2 then
	what = what2
	query = query2
end

-- send
if what == '/' then
	local skel = xml_decode('skel/index.htm')
	local tag = xml_find(skel, 'body')
		local md = markdown(read('satis.md'))
	tag:add(md)
	res = skel:encode() 
elseif what:sub(-9) == ".dir.json" then
	local p = io.popen("ls -p /home/ymte/satis8" .. what:sub(1,-9))
	local data = p:read("*all")
		p:close()
	local files = {}
	data:gsub("([^\t^\n]+)", function(file)
		files[#files+1] = file
	end)
	res = json.encode(files)
else
	res = read(what:sub(2))
end

-- send header
if err then
	io.write("HTTP/1.0 500 Internal Server Error\r\n")
	io.write(string.format("Content-Length: 0\r\n"))
elseif not res then
	io.write("HTTP/1.0 400 Resource Unavailable\r\n")
	io.write(string.format("Content-Length: 0\r\n"))
else
	io.write("HTTP/1.0 200 OK\r\n")
	io.write(string.format("Content-Length: %d\r\n", #res))
end
io.write("\r\n")

-- send data
if res then
	io.write(res)
end

io.close()
