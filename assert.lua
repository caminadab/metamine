#!/usr/bin/lua5.2

local err = io.stdout:read('*a')
if err and err ~= '' then
	print('failed!')
end
