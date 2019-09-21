package.path = package.path ..';../?.lua'
require 'util'
require 'exp'
require 'combineer'
require 'test.langecode'

-- 1 MB
local code,numlijnen = langecode(1024 * 1024 / 10)

-- ontleed
require 'ontleed'
local socket = require 'socket'



--------------------- ONTLEED
-- ⋀([](...))
local voor = socket.gettime()
local lang = ontleed(code)
local na = socket.gettime()
local dt = na - voor

local snelheid = #code / 1024 / 1024 / dt

local leeslijnen = #lang.a
print(string.format('%s lijnen (%.1f MB) ontleed in %d ms (%1.f klijnen/s, %.1f MB/s)',
		leeslijnen, #code/1024/1024, dt*1000, leeslijnen/dt/1000, snelheid))

if numlijnen ~= leeslijnen then
	print('FOUT!', leeslijnen..' lijnen ontleed, maar moeten er '..numlijnen..' zijn')
	local feiten = lang.a
	print(combineer(feiten[#feiten]))
end



--------------------- TYPEER
require 'typeer'

local voor = socket.gettime()
	local types,fouten = typeer(lang)
local na = socket.gettime()
local dt = na - voor
print(string.format('%s feiten getypeerd in %d ms (%.1f kfeit/s, %.1f MB/s)', leeslijnen, dt*1000, leeslijnen/dt/1000, #code/1024/1024/dt))
for i = 1,math.min(#fouten, 10) do
	print(fout2ansi(fouten[i]))
	error'OK'
end

print('Klaar!')
