require 'bouw.gen.js'
require 'vertaal'
require 'vertolk'
require 'combineer'
require 'rapporteer-syntax'
require 'json'

require 'ontleed'
require 'typeer'
require 'oplos'

local socket = require 'socket'
local server = socket.bind('127.0.0.1','1237')
assert(server, 'serverpoort 1237 is niet beschikbaar')
local sockets = {server}
local coros = {}

local function cat(...)
	local abc = {...}
	local r = {}
	for i,t in ipairs(abc) do
		for i,v in ipairs(t) do	
			r[#r+1] = v
		end
	end
	return r
end

local web = lees('bieb/demo.code')

-- DE webfunctie
-- vt: code → {html?, fouten?}
--   fouten: [ fout... ]
--   fout: syntaxfout | typefout | oplosfout
--     syntaxfout: { type="syntax", loc, waarom, waarde }
--       loc: codemirror-locatie
--     typefout: { type="typeer", ? }
--     oplosfout: { type="oplos", ? }
-- 
-- de "fout" als los interpretabel object
function vt(code, naam)

	code = code .. '\n' .. web

	local icode,fouten,gen2bron = vertaal(code)
	local js = ''
	if icode then
		js = jsgen(icode)
	end
	file('a.js', js)
	local fouten = map(fouten, fout2json)

	return {
		js = js,
		gen2bron = gen2bron,
		fouten = fouten,
	}
end

local statusberichten = {
	[200] = "Okee",
	[302] = "Permanente Omleiding",
	[404] = "Niet Gevonden",
	[500] = "Interne Fout",
}

function sendblocking(sock, data)
	local i = 1
	while i < #data do
		local len,err = sock:send(data, i, #data)
		if not len then return nil,err end
		i = i + len + 1 -- laatst verzonden byte
	end
	return #data
end

-- één cliënt serveren
function serveer(sock)
	local len

	-- header
  coroutine.yield()
	local line = sock:receive('*l')
	if not line then
		coroutine.yield()
		line = sock:receive('*l')
	end
	if not line then
		sock:close()
		return false
	end
	local methode,pad = line:match("([^ ]*) ([^ ]*) ([^ ]*)")

	while true do
		local line = sock:receive('*l')
		if not line then
			coroutine.yield()
			line = sock:receive('*l')
		end
		if not line or line == '' then
			break
		end
		
		local len0 = line:match('Content%-Length: (%d+)')
		if len0 then
			len = tonumber(len0)
		end
	end

	-- content
	local inn
	local uit
	if len then
		--coroutine.yield()
		inn = sock:receive(len)
		if not inn then
			coroutine.yield()
			inn = sock:receive(len)
		end
		--print('INN', inn)
	end

	-- uitvoer, log (in), http statuscode
	local uit, inL, status

	-- VERTAAL!
	if pad == '/vt' then
		local internefout
		local ok,j = xpcall(vt, debug.traceback, inn, "in")
		if not ok then internefout = j end

		if not ok then
			print(internefout)
			status = 500
			uit = json.encode {js="onerror(':(')",fouten={}}
		else
			status = 200
			uit = json.encode(j) -- json(html, fouten)
		end

	elseif pad == '/vraag' then
		local mail = string.format(
[[To: ymte@pi
Subject: vraag
From: vraag@metamine.nl

%s
]], inn)
		file('.mail', mail)
		os.execute('sendmail -vt < .mail')
		uit = "deep ping"
		status = 200
		file('.vraag', inn)
		os.execute('cat .vraag >> vragen.log')

	-- LEES!
	else
    pad = pad:gsub('%.%.', '%.')
		if pad == '/' then pad = '/index.html' end
    pad = 'goo/www' .. pad
		uit = file(pad)
		status = 200
		if not uit then
			uit = 'pagina niet gevonden'
			status = 404
		end
	end

	if pad:sub(-4) == ".svg" then
		contenttype = "image/svg+xml"
	elseif pad:sub(-3) == ".js" then
		contenttype = "application/javascript"
	elseif pad:sub(-4) == ".css" then
		contenttype = "text/css"
	elseif pad:sub(-3) == "/vt" then
		contenttype = "application/json"
	else
		contenttype = "text/html; charset=utf-8"
	end

	-- access log
	--print(os.date(), status, pad, string.sub(inL or '', 1, 20))

	-- header
	local h = string.format('HTTP/1.0 %d %s\r\n', status, statusberichten[status])
	local t = {}
	t[#t+1] = h
	t[#t+1] = "Host: localhost\r\n"
	t[#t+1] = "Server: Lua 5.2\r\n"
	t[#t+1] = "Content-Length: "..#uit.."\r\n"
	t[#t+1] = "Content-Type: "..contenttype.."\r\n"
	t[#t+1] = "\r\n"
	t[#t+1] = uit
	sendblocking(sock, table.concat(t))

	sock:close()
end


-- stop als argumenten!
local veto = ...
if veto then return end

--os.execute("chromium http://localhost:1237 >/dev/null 2>/dev/null &")


while true do
	local rs = socket.select(sockets, nil, 0.16) -- rapido

	-- connect
	if rs[1] == server then
		local client = server:accept()
		sockets[client] = #sockets+1
		sockets[#sockets+1] = client
		coros[client] = coroutine.create(serveer, client)
		coroutine.resume(coros[client], client)
		table.remove(rs, 1)
	end

	-- data
	for i=#rs,1,-1 do
		local client = rs[i]
		local coro = coros[client]
		if not coro or coroutine.status(coro) ~= 'suspended' then
			table.remove(sockets, sockets[client]) --client)
			sockets[client] = nil
			coros[client] = nil
		else
			local unfinished,err = coroutine.resume(coros[client])
			if err then print('ERR', err) end
			if not unfinished then
				table.remove(sockets, sockets[client]) --client)
				sockets[client] = nil
				coros[client] = nil
			end
		end
	end

end
