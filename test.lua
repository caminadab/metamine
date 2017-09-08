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
		local res,vals = eval(sexp)
		if not res then
			local prog = compile(sexp)
			print('Niet goed!')
			print('File: '..line)
			print('Programma:')
			print(unparseProg(prog,vals))
		end
	end
end
