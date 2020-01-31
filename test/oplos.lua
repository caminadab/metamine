require 'oplos'
require 'vertaal'
require 'fout'

local code = "b := 1\nc := 2\napp = b\nuit.vars = []"
local b,fouten = oplos(ontleed(code), "app")
print(code)
print(combineer(b))
for i,fout in ipairs(fouten) do
	print(fout2ansi(fout))
	os.exit()
end
