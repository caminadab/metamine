#!/usr/bin/lua5.2
require 'util'
require 'interpret'
require 'compile'
require 'eval'
require 'sas'

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

			local ok,solved = pcall(solve,sexp)
			if not ok then
				io.write(color.red)
				print('Onoplosbaar!')
				print(solved)
				io.write(color.white)
			end
				

			local ok,prog = pcall(compile,solved)
			if not ok then
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
