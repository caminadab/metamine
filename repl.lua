require 'vertaal'
require 'doe'
require 'naarjavascript'
require 'fout'

function repl()
	local namen = {}
	local prog = ''
	while true do
		io.write('> ')
		local line = io.read()
		if not line then
			break
		end
		if line == 'stop' then
			prog = ''
		end
		prog = prog .. '\n' .. line
		local app,fouten = vertaal(prog, "ifunc")
		for i,fout in ipairs(fouten) do
			print(fout2string(fout))
		end
		if app then
			for blok in pairs(app.punten) do
				print(blok)
			end
			doe(app)
		end
	end
end

if not test then
	repl()
end
