-- ESC [ n ; m H, where n is the row number and m the column number.
function pos(x,y)
	return '\x1B['..y..';'..x..'H'
end
function clear()
	return '\x1B[2J'
end
clearline = '\x1B[K'
up = '\x1B[A'

