#!/usr/bin/lua5.2
require 'util'
require 'interpret'
require 'compile'
require 'eval'
require 'sas'

local src2 = [[
v = i | t
bv = bi | bt
bv = 'i3e'
bi = 'i' || i || 'e'
v
]]

local src = [[
y = 'a'
x = y || 'b'
x
]]

function known(sexp)
	if atom(sexp) then
		if isconstant(sexp) then
			return {':',sexp,'constant'}
		elseif isvar(sexp) then
			return sexp
		else
			return sexp
		end
	end
	return sexp
end

known = recursive(known)

print(unparse(known(parse(src))))
print()

-- slim gedeelte
local a,b,c,d,e
a = parse(src)
b = solve(a)
_,c = pcall(compile, b)
_,d,e = pcall(interpret, c)
print('Bron')
print(src)
print()
print('Opgelost')
print(unparse(b))
print()
print('Programma')
print(unparseProg(c, e))
print()
print('Resultaat')
print(unparse(d))
print()

local files = io.popen('ls test')

while true do
	local line = files:read('*l')
	if not line then break end

	if line:sub(-4) == '.sas' then
		local sas = file('test/'..line)
		local sexp = parse(sas)
		local ok,res,vals = pcall(eval,sexp)
		if not ok or not res then
			print()
			print(color.yellow..'File: '..line..color.white)
			print(sas)

			local ok,solved = pcall(solve,sexp)
			if not ok then
				io.write(color.red)
				print('Onoplosbaar!')
				print(solved)
				io.write(color.white)
			end

			local ok,prog = pcall(compile,solved)
			if not ok then
				print('Opgelost:')
				print(unparse(solved))
				io.write(color.red)
				print(prog)
				io.write(color.white)
			else
				io.write(color.white)
				print('Niet goed!')
				print('Programma:')
				print(unparseProg(prog,vals))
			end
		end
	end
end
