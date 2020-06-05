require 'socket'

local host = socket.bind('127.0.0.1', '10101')

assert(host)
assert(host.accept)

print('host:', host)

