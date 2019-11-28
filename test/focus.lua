require 'bouw.focus'
require 'ontleed'
require 'rapport'
require 'util'


local f = focus(ontleedexp('2 + 3'))
--assert(next(f.punten) and not next(f.punten, next(f.punten)))

local f = focus(ontleedexp('1 + muis.x'))

--local f = focus(ontleed"a := 0\nzolang a' > 10\n\ta := a' + 1\neind")

--file('a.html', graaf2html(f))
--os.execute('firefox a.html')
--assert(next(f.punten) and next(f.punten, next(f.punten)) and not next(f.punten, next(f.punten, next(f.punten))))
