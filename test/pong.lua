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
	print('bron: '..numlines..' lines, '..#prog..' bytes')
end

local voor = socket.gettime()

local app = vertaal(prog)
local n = 0
for i,ins in ipairs(app) do
	n = n + #exp2string(ins)
end
print('resultaat: '..n..' bytes')

local na = socket.gettime()
local dt = math.floor((na - voor)*100)/100
print('vertaal(pong) duurde '..dt..' s!')


