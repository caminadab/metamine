require 'func'
require 'solve'
require 'compile'
require 'interpret'

eval = compose(interpret, compile, solve)
