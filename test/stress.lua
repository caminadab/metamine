package.path = package.path ..';../?.lua'
require 'util'
require 'exp'
require 'deparse'
require 'typify'
require 'test.langecode'
require 'build.codegen'

-- 1 MB
local code,numlijnen = langecode(124 * 1024 / 10)

-- parse
require 'parse'
local socket = require 'socket'

--------------------- ONTLEED
-- ⋀([](...))
local voor = socket.gettime()
local lang = parse(code)
local na = socket.gettime()
local dt = na - voor

local snelheid = #code / 1000 / dt

local leeslijnen = #lang.a
print(string.format('%s lijnen (%.1f kB) parse in %d ms (%1.f klijnen/s, %.1f kB/s)',
		leeslijnen, #code/1000, dt*1000, leeslijnen/dt/1000, snelheid))

if numlijnen ~= leeslijnen then
	print('FOUT!', leeslijnen..' lijnen parse, maar moeten er '..numlijnen..' zijn')
	local feiten = lang.a
	print(deparse(feiten[#feiten]))
end



--------------------- TYPEER
require 'typify'

local voor = socket.gettime()
	local types,fouten = typify(lang)
local na = socket.gettime()
local dt = na - voor
print(string.format('%s feiten getypifyd in %d ms (%.1f kfeit/s, %.1f kB/s)', leeslijnen, dt*1000, leeslijnen/dt/1000, #code/1000/dt))
for i = 1,math.min(#fouten, 10) do
	print(fout2ansi(fouten[i]))
end

do return end



--------------------- OPLOS
local voor = socket.gettime()
	local exp = solve(lang, "uit")
local na = socket.gettime()
local dt = na - voor
print(string.format('%s feiten opgelost in %d ms (%.1f kfeit/s, %.1f kB/s)', leeslijnen, dt*1000, leeslijnen/dt/1000, #code/1000/dt))
for i = 1,math.min(#fouten, 10) do
	print(fout2ansi(fouten[i]))
end





--------------------- CODEGEN
local voor = socket.gettime()
	local prog = codegen(exp)
local na = socket.gettime()
local dt = na - voor
print(string.format('%s feiten opgelost in %d ms (%.1f kfeit/s, %.1f kB/s)', leeslijnen, dt*1000, leeslijnen/dt/1000, #code/1000/dt))
