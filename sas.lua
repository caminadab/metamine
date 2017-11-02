require 'parse'

local fsas = ebnf(file('ebnf/sas.ebnf'))

function sas(s)
end


require 'lisp'
print(unebnf(fsas))
local chunk = parse(fsas, file('syntax.sas'))
print(unlisp(chunk))
