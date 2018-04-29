local function index(a,b)
	return a[b+1]
end
veld = 20
scherm = {1280, 1024, }
function love.update()
	links = {((5+(love.keyboard.isDown("right") and 1 or 0))-(love.keyboard.isDown("left") and 1 or 0)), (love.keyboard.isDown("up") and 1 or 0), }
	linksScherm = ((links/veld)*scherm)
end
require 'lisp'
love.window.setMode(1280,1024,{fullscreen=true})
function love.draw()
	for i,v in ipairs(stdout) do
		love.graphics.circle('fill', v[1], v[2], 20)
	end
	love.graphics.print("veld = "..unlisp(veld), 10, 16)
	love.graphics.print("scherm = "..unlisp(scherm), 10, 32)
	love.graphics.print("links = "..unlisp(links), 10, 48)
	love.graphics.print("linksScherm = "..unlisp(linksScherm), 10, 64)
end
