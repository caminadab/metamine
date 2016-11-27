-- debug
local co
local breakpoints = {}
local reg = debug.getregistry()

local function hook()
	local info = debug.getinfo(co, 2, 'fl')
	local file = reg._LOADED[info.func]
	local line = info.currentline
	print(coroutine.status(co))
	print(file,line)
	if breakpoints[file] and breakpoints[file][line] then
		js.global:setBreakLine(file,line-1)
		print('BREAK')
		debug.sethook(co)
		print(coroutine.status(co))
		coroutine.yield()
		print('hoi')
	end
end

function addBreakpoint(file,line)
	breakpoints[file] = breakpoints[file] or {}
	breakpoints[file][line] = true
end
function removeBreakpoint(file,line)
	breakpoints[file][line] = nil
end

function run()
	if co then
		print(co, coroutine.status(co))
	end
	
	if co and coroutine.status(co) == 'suspended' then
		print('RESUME')
		debug.sethook(co, hook, 'l')
		coroutine.resume(co)
		debug.sethook(co)
		return
	end
	print('START')
	local main = read('main.lua')
	local func = load(main)
	co = coroutine.create(func)
	reg._LOADED = {}
	reg._LOADED['main'] = func
	reg._LOADED[func] = 'main'
	require 'debug'
	debug.sethook(co, hook, 'l')
	coroutine.resume(co)
	print('STOP', coroutine.status(co))
	debug.sethook(co)
end