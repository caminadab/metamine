require 'exp'

local function vassert(i, moetnaam)
	local naam = varnaam(i)
	assert(naam == moetnaam, 'varnaam('..i..') = "'..naam..'" maar moet "'..moetnaam..'" zijn')
end


vassert(1, 'A')
vassert(2, 'B')
vassert(25, 'Y')
vassert(26, 'Z')
vassert(27, 'AA')
vassert(27+25, 'AZ')
vassert(26 + 26*26 + 1, 'AAA')
vassert(26 + 26*26 + 2, 'AAB')
