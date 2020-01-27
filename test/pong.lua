require 'util'
require 'vertaal'
require 'doe'
local socket = require 'socket'

local pong = file 'ex/pong.code'
local bieb = file 'bieb/std.code'
local prog = pong .. bieb

do
	local _,numlines = prog:gsub('\n', ' ')
	print('==== vertaal(pong) ====')
	print(numlines..' lines')
	print(#prog..' bytes')
end

local voor = socket.gettime()
local a = vertaal(prog)
local na = socket.gettime()
local dt = math.floor((na - voor)*100)/100
print('vertaal(pong) duurde '..dt..' s!')


