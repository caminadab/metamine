require 'util'
require 'exp'

-- fmt: {rood} is {exp} maar moet {cyaan} zijn
function fout(type, loc, fmt, ...)
	-- Typefout: a is int (loc1) maar moet tekst zijn (loc2)
	local t = {
		loc = loc,
		type = type,
		fmt = fmt,
		args = {...},
	}
	return t
end

-- loc, fmt, ...
function executiefout(...) return fout("executie", ...) end
function syntaxfout(...) return fout("syntax", ...) end
function oplosfout(...) return fout("oplos", ...) end
function typeerfout(...) return fout("typeer", ...) end

function jsloc(loc)
	loc = loc or nergens
	local jloc = {
		anchor = {
			ch = loc.x1 - 1,
			line = loc.y1 - 1,
		},
		head = {
			ch = loc.x2 - 1,
			line = loc.y2 - 1,
		},
		source = loc.bron,
	}
	return jloc
end

-- → {loc: loc, html: demohtml}
function fout2json(fout)
	local hfout = {}
	hfout.loc = jsloc(fout.loc)
	hfout.type = fout.type

	local i = 0
	local t = fout.args
	local html = fout.fmt:gsub('{([^}]*)}', function (spec)
		i = i + 1
		if spec == 'loc' then
			return '<u>' .. loctekst(t[i]) .. '</u>'
		elseif spec == 'rood' then
			return '<span color="red">'.. t[i] .. '</span>'
		elseif spec == 'code' then
			return '<b>' .. tostring(t[i]) .. '</b>'
		elseif spec == 'exp' then
			return '<span color="cyan">' .. combineer(t[i]) .. '</span>'
		elseif spec == 'int' then
			return tostring(math.floor(t[i]))
		elseif spec == 'cyaan' then
			return '<span color="cyan">' .. tostring(t[i]) .. '</span>'
		else
			error('onbekend type: '..spec)
		end
	end
	)
	hfout.html = html
	return hfout
end

function fout2ansi(fout)
	local loc =  ansi.underline .. loctekst(fout.loc) .. ansi.normal
	local type = color.brightred .. fout.type:gsub('^(.)', string.upper) .. 'fout' .. color.white .. ': '
	local i = 0
	local t = fout.args
	local ansi = loc .. '\t' .. type .. '\t' .. fout.fmt:gsub('{([^}]*)}', function (spec)
		i = i + 1
		if spec == 'loc' then
			return ansi.underline .. loctekst(t[i]) .. ansi.normal
		elseif spec == 'rood' then
			return color.brightred .. t[i] .. color.white
		elseif spec == 'code' then
			return color.brightyellow .. tostring(t[i]) .. color.white
		elseif spec == 'exp' then
			return color.brightcyan .. combineer(t[i]) .. color.white
		elseif spec == 'int' then
			return tostring(math.floor(t[i]))
		elseif spec == 'cyaan' then
			return color.brightcyan .. tostring(t[i]) .. color.white
		else
			error('onbekend type: '..spec)
		end
	end
	)
	return ansi
end
			
function fout2string(fout)
	local loc =  loctekst(fout.loc)
	local type = fout.type:gsub('^(.)', string.upper) .. 'fout' .. ': '
	local i = 0
	local t = fout.args
	local string = loc .. '\t' .. type .. '\t' .. fout.fmt:gsub('{([^}]*)}', function (spec)
		i = i + 1
		if spec == 'loc' then
			return loctekst(t[i])
		elseif spec == 'rood' then
			return t[i]
		elseif spec == 'code' then
			return tostring(t[i])
		elseif spec == 'exp' then
			return combineer(t[i])
		elseif spec == 'int' then
			return tostring(math.floor(t[i]))
		elseif spec == 'cyaan' then
			return tostring(t[i])
		else
			error('onbekend type: '..spec)
		end
	end
	)
	return string
end

--[[
	oplos
	type
	zelftest
	executie
]]

-- f[#f+1] = fout("oplos", "{code} is {type} ({loc}) maar moet {type} ({loc}) zijn")
