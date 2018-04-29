local function index(a,b)
	return a[b+1]
end
rechts = {15, 0, }
grechts = {((index (rechts, 0)/20)*1280), (1024-((index (rechts, 1)/20)*1024)), }
bal = {10, 10, }
gbal = {((index (bal, 0)/20)*1280), (1024-((index (bal, 1)/20)*1024)), }
function love.update()
	links = {((5+(love.keyboard.isDown("right") and 1 or 0))-(love.keyboard.isDown("left") and 1 or 0)), (love.keyboard.isDown("up") and 1 or 0), }
	glinks = {((index (links, 0)/20)*1280), (1024-((index (links, 1)/20)*1024)), }
	cirkels = {glinks, grechts, gbal, }
	stdout = cirkels
end
require 'lisp'
love.window.setMode(1280,1024,{fullscreen=true})
function love.draw()
	for i,v in ipairs(stdout) do
		love.graphics.circle('fill', v[1], v[2], 20)
	end
		love.graphics.print("rechts = "..unlisp(rechts), 10, 16)
	love.graphics.print("grechts = "..unlisp(grechts), 10, 32)
	love.graphics.print("bal = "..unlisp(bal), 10, 48)
	love.graphics.print("gbal = "..unlisp(gbal), 10, 64)
	love.graphics.print("links = "..unlisp(links), 10, 80)
	love.graphics.print("glinks = "..unlisp(glinks), 10, 96)
	love.graphics.print("cirkels = "..unlisp(cirkels), 10, 112)
	love.graphics.print("stdout = "..unlisp(stdout), 10, 128)
end
