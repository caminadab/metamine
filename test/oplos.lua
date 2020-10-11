require 'solve'
require 'compile'
require 'fout'

local code = "b := 1\nc := 2\napp = b\nin.vars = []"
local b,fouten = solve(parse(code), "app")
print(code)
print(deparse(b))
for i,fout in ipairs(fouten) do
	print(fout2ansi(fout))
	os.exit()
end
