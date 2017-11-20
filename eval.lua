require 'func'
require 'compile'
require 'interpret'

eval = compose(interpret, compile)
