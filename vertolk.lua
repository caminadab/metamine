require 'lisp'

local lijst = file('bieb/en.lst')

NL2EN = {}
EN2NL = {}

for NL, EN in lijst:gmatch('(%w+)\t(%w+)\n') do
	NL2EN[NL] = EN
	EN2NL[EN] = NL
end

function vertolk(asb)
	for exp in boompairs(asb) do
		if isatoom(exp) then
			if EN2NL[exp.v] then
				exp.v = EN2NL[exp.v]
			end
		end
	end
	return asb
end

if test then
	require 'ontleed'
	local a = ontleedexp("a = sqrt(3)")
	local b = vertolk(a)
	assert(moes(b) == '=(a wortel(3))', e2s(b))
end
