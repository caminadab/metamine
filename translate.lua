require 'lisp'

local lijst = file('lib/en.lst')

NL2EN = {}
EN2NL = {}

for NL, EN in lijst:gmatch('([%w%.]+)\t([%w%.]+)\n') do
	NL2EN[NL] = EN
	EN2NL[EN] = NL
end

function translate(asb)
	for exp in treepairs(asb) do
		if isatom(exp) then
			if EN2NL[exp.v] then
				exp.v = EN2NL[exp.v]
			end
		end
	end
	return asb
end

if test then
	require 'parse'
	local a = parseexp("a = sqrt(3)")
	local b = translate(a)
	assert(hash(b) == '=(a wortel(3))', e2s(b))
end
