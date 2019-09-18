require 'ontleed'

function unlisp(x)
	local t = {}
	if not x then return '<niets>' end
	local function U(y)
		if type(y) ~= 'table' then
			t[#t+1] = '? '
			y = nil
		end
		if y and y.v then
			t[#t+1] = y.v
			return
		end
		if y and y.f then
			t[#t+1] = y.f.v
			t[#t+1] = '('
			for i,v in ipairs(y) do
				U(v)
				t[#t+1] = ' '
			end
			t[#t] = ')'
		else
			t[#t+1] = '?'
		end
	end
	U(x)
	return table.concat(t)
end

function file(name, data)
	if not data then
		local f = io.open(name, 'r')
		if not f then return false, 'bestand niet gevonden: '..name  end --error('file-not-found ' .. name) end
		data = f:read("*a")
		f:close()
		return data
	else
		local f = io.open(name, 'w')
		assert(f, 'onopenbaar: '..name)
		f:write(data)
		f:close()
	end
end

local totaal,goed = 0,0
local function passert(ok, msg)
	totaal = totaal + 1
	if not ok then
		print('ASSERT FAILED: ' .. msg)
		print()
	else
		goed = goed + 1
	end
end

local tests = file('TESTS')
for code in tests:gmatch('(.-)\n\n') do
	local taal,moet = code:match('(.*)\n([^n]-)$')
	if taal and moet then
	--print()
	--print(taal, moet)
	local lisp = unlisp(ontleed(taal))
	passert(lisp == moet, string.format('ontleed("%s") moet %s zijn maar is %s', taal, moet, lisp))
end
end

print(string.format('%d/%d goed (%.2d%%)', goed, totaal, goed/totaal*100))
