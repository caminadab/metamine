require 'util'
require 'compile'
require 'doe'
local socket = require 'socket'

local pong = file 'ex/pong.code'
local lib = file 'lib/std.code'
local prog = pong .. lib

do
	local _,numlines = prog:gsub('\n', ' ')
	print('==== compile(pong) ====')
	print('bron: '..numlines..' lines, '..#prog..' bytes')
end

local voor = socket.gettime()

local app = compile(prog)
local n = 0
assert(app, 'pong kon niet eens gecompileerd worden')
for i,ins in ipairs(app) do
	n = n + #exp2string(ins)
end
print('resultaat: '..n..' bytes')

local na = socket.gettime()
local dt = math.floor((na - voor)*1000)
print('compile(pong) duurde '..dt..'ms')


