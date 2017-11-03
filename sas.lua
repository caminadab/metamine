require 'parse'

local fsas = ebnf(file('ebnf/sas.ebnf'))

function sas(s)
end


require 'lisp'
print(unebnf(fsas))

local src = file('syntax.sas')
local src = '1 + 2'
local chunk = parse(fsas, src)
print(unlisp(chunk))
