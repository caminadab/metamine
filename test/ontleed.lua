require 'parse'
require 'util'

function unlisp(x)
	local t = {}
	if not x then return '<niets>' end
	local function U(y)

		if type(y) ~= 'table' then
			t[#t+1] = '? '
			y = nil
		end

		if isatom(y) then
			t[#t+1] = atom(y)
		end

		-- obj
		if isobj(y) then
			if obj(y) ~= ',' then
				t[#t+1] = obj(y)
				t[#t+1] = '('
			end
			for i,v in ipairs(y) do
				if i > 1 then
					t[#t+1] = ' '
				end
				U(v)
			end
			if obj(y) ~= ',' then
				t[#t+1] = ')'
			end
		end

		-- fn
		if isfn(y) then
			t[#t+1] = fn(y)
			t[#t+1] = '('
			U(arg(y))
			t[#t+1] = ')'
		end
	end

	U(x)

	return table.concat(t)
end

local totaal,goed = 0,0
local function passert(ok, msg)
	totaal = totaal + 1
	if not ok then
		--print('ASSERT FAILED: ' .. msg)
	else
		goed = goed + 1
	end
end

local tests = file('test/parse.lst')
for code in tests:gmatch('(.-)\n\n') do
	local taal,moet = code:match('(.*)\n([^n]-)$')
	if taal and moet then
		--print()
		--print(taal, moet)
		local lisp = unlisp(parseexp(taal))
		passert(lisp == moet, string.format('parse("%s") moet %s zijn maar is %s', taal, moet, lisp))
	end
end

print(string.format('%d/%d goed (%.2d%%)', goed, totaal, goed/totaal*100))
