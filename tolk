#!/usr/bin/lua
require 'util'

NL2EN = {}
EN2NL = {}

function toepas(pad)
	local flijst = io.open(pad) 
	local lijst = flijst:read('*a')
	flijst:close()


	for NL, EN in lijst:gmatch('([%w%.]+)\t([%w%.]+)\n') do
		NL2EN[NL] = EN
		EN2NL[EN] = NL
	end
end

toepas('bieb/en.lst')
toepas('bieb/demo.lst')


local inn, uit = ...
if not inn and not uit then error('gebruik: tolk [IN] [UIT]') end
if not inn then error('IN niet gedefineerd') end
local code = file((inn))
if not code then error('bestand niet gevonden') end

local res = code:gsub('([%w%.]+)', function (token)
		return NL2EN[token] or token
end)

local res = res:gsub('(%w+)', function (token)
		return NL2EN[token] or token
end)

if uit then
	file(uit, res)
else
	print(res)
end

