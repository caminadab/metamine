require 'util'

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
function executiefout(...) return fout("Executie", ...) end
function syntaxfout(...) return fout("Syntax", ...) end
function oplosfout(...) return fout("Oplos", ...) end
function typeerfout(...) return fout("Type", ...) end

function fout2ansi(fout)
	local loc =  ansi.underline .. loctekst(fout.loc) .. ansi.normal
	local type = color.brightred .. fout.type .. 'fout' .. color.white .. ': '
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
			

--[[
	oplos
	type
	zelftest
	executie
]]

-- f[#f+1] = fout("oplos", "{code} is {type} ({loc}) maar moet {type} ({loc}) zijn")
