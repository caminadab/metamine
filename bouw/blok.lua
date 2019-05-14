function maakblok(naam, stats)
end

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
]]
