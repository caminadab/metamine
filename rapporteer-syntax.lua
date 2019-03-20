local rapport = [[
<html>
	<meta charset="utf-8">
	<style>
		html { background: black; color: white; }
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
</pre>
</html>
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
		pos = code:find('\n', pos) + 1
		if not pos then return false end
	end
	pos = pos + x - 1
	return pos
end

function locsub(code, loc)
	local apos = locvind(code, loc.x1, loc.y1)
	local bpos = locvind(code, loc.x2, loc.y2)
	return string.sub(code, apos, bpos-1)
end

assert(locvind("a = 3\nb = 1 + 2\n", 5, 2) == 11)
print(locsub("a = 3\nb = 1 + 2\n", {x1=1,y1=2,x2=5,y2=3}))
assert(locsub("a = 3\nb = 1 + 2\n", {x1=1,y1=2,x2=6,y2=2}) == "b = 1")

function printloc(loc)
	if loc.y1 == loc.y2 and loc.x1 == loc.x2 then
		io.write(string.format("%d:%d", loc.y1, loc.x1))
	elseif loc.y1 == loc.y2 then
		io.write(string.format("%d:%d-%d", loc.y1, loc.x1, loc.x2))
	else
		io.write(string.format("%d:%d-%d:%d", loc.y1, loc.x1, loc.y2, loc.x2))
	end
	print()
end

function rapporteer_syntax(code,elementen,stijl)
	local gesorteerd = {}
	for element,tooltip in pairs(elementen) do
		if isatoom(element) then
			gesorteerd[#gesorteerd+1] = element
		end
	end
	table.sort(gesorteerd, function(a,b) return loclt(a.loc, b.loc) end)

	local tooltips = {}
	local vorige = gesorteerd[1].loc
	for i,token in ipairs(gesorteerd) do
		local loc = token.loc

		local vullerloc = {x1=vorige.x2,y1=vorige.y2,x2=loc.x1,y2=loc.y1}
		local vuller = locsub(code, vullerloc)
		local token0 = locsub(code, loc)
		--io.write('vuller ', vuller, ' '); printloc(vullerloc)
		--io.write('token ', token0, ' '); printloc(loc)

		local tooltip = string.format(htmltoken, "vuller",  vuller, "")
		tooltips[#tooltips+1] = tooltip
		local tooltip = string.format(htmltoken, stijl[token] or "", token0, elementen[token])
		tooltips[#tooltips+1] = tooltip
		vorige = loc
	end

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
	return html
end
