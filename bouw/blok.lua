require 'combineer'
require 'exp'
require 'lisp'

--[[
op: * / + - 
arg: label | woord | int
ins: op args
blok:
	stats: lijst ins
	epiloog = stats.laatste
	epiloog = |
		ga1 (BLOK)
		ga3 (VAL, BLOK, BLOK)
		ga4 (VAL, BLOK, BLOK)
		eind
		stop
]]

function blok2tekst(self)
	local t = {}
	t[#t+1] = self.naam.v..':'
	for i,stat in ipairs(self.stats) do
		t[#t+1] = '  '..combineer(stat)
		-- met locatie
		--t[#t+1] = '  '..combineer(stat)..'  '..(stat.loc and loctekst(stat.loc) or '')
	end
	t[#t+1] = '  '..combineer(self.epiloog)
	return table.concat(t, '\n')
end

function leesblok(tekst)
	local label,rest = tekst:match '^([^:]+):(.*)'
	local stats = ontleed(rest)
	local epiloog = stats[#stats]
	stats[#stats] = nil

	return maakblok(X(label), stats, epiloog)
end

function maakblok(naam, stats, epiloog)
	--assert(atoom(epiloog) == 'eind' or atoom(epiloog) == 'stop' or fn(epiloog) == 'ga' or fn(epiloog) == 'ret', 'foute epiloog: '..combineer(epiloog))
	--print('EPI', combineer(epiloog))
	--if isfn(epiloog) and isobj(epiloog.a) then
		--assert(#epiloog.a == 3 or #epiloog.a == 4, 'onjuiste sprong')
	--end

	local blok = {
		naam = naam,
		stats = stats,
		epiloog = epiloog,
	}
	setmetatable(blok, {__tostring = blok2tekst})
	return blok
end


if test then
	require 'ontleed'
	local a = leesblok [[
start:
  a := 3
  stop
]]
	assert(a.naam.v == 'start')

	local b = leesblok [[
start:
  a := 2
  ga lus
]]

	local c = leesblok "start:\n b := 1\n ga(b,c,d)\n "

	local d = leesblok "start:\n a := 3\n ga(stop, 2, 3)\n "
end
