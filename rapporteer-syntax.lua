local rapport = [[
	<meta charset="utf-8" >
	<style>
		pre { background: black; color: white; }
		pre {}
		.code {
			font-size: 20px;
			font-family: Courier;
			font-weight: bold;
		}

		.goed { color: green; }
		.fout { color: red; }

		.tooltip .infobox {
			visibility: hidden;
			position: absolute;
			z-index: 1;
			color: yellow;
			left: 50%%;
			margin-top: 20px;
			margin-left: 0px;
			width: 200px;
			text-align: center;
		}
		.tooltip .infobox .info {
			background: #330;
		}

		.vuller {
			color: #888;
		}

		.tooltip:hover .infobox:hover {
			visibility: hidden;
			opacity: 1;
		}

		.tooltip:hover .infobox {
			visibility: visible;
			opacity: 1;
		}

		.tooltip {
			position: relative;
		}
	</style>
	<pre class='code'>%s</pre>
]]

-- .format(tekst,tooltip)
local htmltoken = [[<span class='tooltip %s'>%s]]..
	[[<span class='infobox'><span class='info'>%s</span></span>]]..
	[[</span>]]

--
local function loclt(a,b)
	if  a.y1 > b.y1 then return false end
	if  a.y1 < b.y1 then return true end
	if  a.x1 > b.x1 then return false end
	if  a.x1 < b.x1 then return true end

	if  a.y2 > b.y2 then return false end
	if  a.y2 < b.y2 then return true end
	if  a.x2 > b.x2 then return false end
	if  a.x2 < b.x2 then return true end
	return false
end

function locvind(code, x, y)
	local pos = 1
	for i=1,y-1 do
		pos = code:find('\n', pos)
		if not pos then return false end
		pos = pos + 1
	end
	pos = pos + x - 1
	if pos > #code+1 then
		return false
	end
	return pos
end

function locsub(code, loc)
	local apos = locvind(code, loc.x1, loc.y1)
	local bpos = locvind(code, loc.x2, loc.y2)
	if not apos or not bpos then return false end
	return string.sub(code, apos, bpos-1)
end

assert(locvind("a", 1, 1) == 1)
assert(locvind("a\n", 2, 1) == 2)
assert(locvind("a\n", 1, 3) == false)
assert(locvind("a\nb", 1, 2) == 3)
assert(locvind("a = 3\nb = 1 + 2\n", 5, 2) == 11)

assert(locsub("a = 3\nb = 1 + 2\n", {x1=1,y1=2,x2=6,y2=2}) == "b = 1")

assert(locsub("a\nb", {x1=1,y1=2,x2=2,y2=2}) == "b")
assert(locsub("a\nb\n", {x1=1,y1=2,x2=3,y2=2}) == "b\n")

function rapporteer_syntax(code,labels,stijl)
	local gesorteerd = {}
	for exp,label in pairs(labels) do
		if isatoom(exp) then
			gesorteerd[#gesorteerd+1] = exp
		end
	end
	if #gesorteerd == 0 then
		gesorteerd = { {v=X'niets', loc={x1=1,y1=1,x2=1,y2=1}} }
	end
	table.sort(gesorteerd, function(a,b) return loclt(a.loc, b.loc) end)

	local tooltips = {}
	local vorige = {x1=1,y1=1,x2=1,y2=1}
	for i,token in ipairs(gesorteerd) do
		local loc = token.loc

		local vullerloc = {x1=vorige.x2,y1=vorige.y2,x2=loc.x1,y2=loc.y1}
		local vuller = locsub(code, vullerloc)
		local token0 = locsub(code, loc)
		--io.write('vuller ', vuller, ' '); printloc(vullerloc)
		--io.write('token ', token0, ' '); printloc(loc)

		local tooltip = string.format(htmltoken, "vuller",  vuller, "")
		tooltips[#tooltips+1] = tooltip
		local tooltip = string.format(htmltoken, stijl[token] or "", token0, labels[token])
		tooltips[#tooltips+1] = tooltip
		vorige = loc
	end

	-- laatste vuller
	local vuller = code:sub(locvind(code, vorige.x2, vorige.y2) or 1)
	local tooltip = string.format(htmltoken, "vuller",  vuller, "")
	tooltips[#tooltips+1] = tooltip

	-- [(tip, 
	local function r(tak)
		if isatoom(tak) then
			local tooltip = string.format(token, tak.v, "test")
			tooltips[#tooltips+1] = tooltip
		else
			r(tak.fn)
			for i,v in ipairs(tak) do
				r(tak[i])
			end
		end
	end
	--r(boom)
	local html = string.format(rapport, table.concat(tooltips))
	local html = html:gsub('\t', '  ')
	return html
end
