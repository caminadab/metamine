
function assembleer(asm)
	local naam = os.tmpname()
	local snaam = naam .. '.s'
	local onaam = naam .. '.o'

	-- schrijf asm
	local bd = io.open(snaam, 'w')
	bd:write(asm)
	bd:close()

	os.execute(string.format(
		'as -g %s -o %s --no-pad-section -R', snaam, onaam
	))

	-- lees obj
	local bd = io.open(onaam, 'r')
	local obj = bd:read('*a')
	bd:close()

	if false then
		os.remove(snaam)
		os.remove(onaam)
	end

	return obj
end
