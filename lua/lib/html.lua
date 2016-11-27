require "web/xml"
require "web/url"

html = {}

setmetatable(html, {__index = function(tt,key)
	return function(text)
		local x = xml(key, text)
		x.id = btoa(uuid())
		
		function x:regcallbacks(web)
			if type(self) ~= 'table' then
				return
			end
			
			-- loop tags
			for k,v in pairs(self) do
				if type(v) == 'function' and k:sub(1,2) == 'on' then
					web.callbacks[self.id] = v
					web.callbacks_timeout[self.id] = now() + 3600
				end
			end
			
			-- loop children
			if self._children then
				for i,v in pairs(self._children) do
					if v._tag then
						v:regcallbacks(web)
					end
				end
			end
		end
		
		return x
	end
end
})

--[[
callback:	

address:	"ws://ymte.net:80/"
start:
			ws-open				ws, address

id:			get-table			"
row:		row-create
			table-row-add		row, id
]]

-- build
function html.page(web)
	local page = html.html()
	local encode = page.encode
	local add = page.add
	local body = html.body()
	
	function page:add(x)
		body:add(x)
	end
	
	-- assumes callbacks are loaded
	function page:addjs()
		local script = xml("script")
		script.type = "text/javascript"
		
		-- open websocket
		script:add('ws = new WebSocket("ws://' .. url.encode(web.host) .. ':80");')
		
		script:add('ws.onopen = function() { console.log("is now open!")}; ')
		
		-- handle messages
		script:add("ws.onmessage = function(obj) { var ev = JSON.parse(obj.data); eval(ev.call)(ev.args[0], ev.args[1], ev.args[2], ev.args[3], ev.args[4]); };")
		
		-- refresh on close or error
		script:add("ws.onclose = function() { window.location.reload() };")
		script:add("ws.onerror = function() { window.location.reload() };")
		
		-- popup
		script:add("popup = function(a) { alert(a) };")
		
		-- html list
		--script:add("add = function(id,el) { var fresh = document.createElement('div'); fresh.innerHTML = el; document.getElementById(id).appendChild(fresh.firstChild); };")
		script:add("add = function(id,el) { if (document.getElementById(id) != null) document.getElementById(id).innerHTML += el; };")
		
		script:add("remove = function(id) { var el = document.getElementById(id); el.parentNode.removeChild(el); };")
		script:add("change = function(id,el) {  if (document.getElementById(id) != null) document.getElementById(id).innerHTML = el; };")
		
		-- progress
		script:add("progress = function(id, normal) { var el = document.getElementById(id); el.value = normal * 1000000;};")
		
		-- notify
		script:add("notify = function(id,value) { gid = id; var msg = JSON.stringify({id: id, value: value}); ws.send(msg);}")
		
		self:add(script)
	end
	
	function page:encode()
		local head = xml("head")
		local meta = xml("meta")
		meta.charset = "UTF-8"
		meta.name = 'viewport'
		meta.content = 'width=device-width, initial-scale=1'
		head:add(meta)
		
		body.oncontextmenu = "return false"
		
		if page.title then
			local title = xml("title", page.title)
			head:add(title)
		end
		
		-- comment
		body:regcallbacks(web)
		
		-- websocket code
		self:addjs()		
		
		if page.style then
			local style = xml("style")
			style.type = "text/css"
			local file = io.open(page.style)
			local text = file:read("*all")
			style:add(text)
			file:close()
			body:add(style)
		end
		
		add(page, head)
		add(page, body)
		
		return "<!DOCTYPE HTML>"  .. encode(self)
	end
	
	return page
end

return html