local sdl = require 'sdl2'
local ffi = require 'ffi'
local C = ffi.C

sdl.init(sdl.INIT_VIDEO)

require 'util'
for k in spairs(sdl) do
	--print(k)
end
--do return end

local window = sdl.createWindow("Taal",
                                sdl.WINDOWPOS_CENTERED,
                                sdl.WINDOWPOS_CENTERED,
                                1280,
                                720,
                                sdl.WINDOW_SHOWN + sdl.WINDOW_RESIZABLE)

local windowsurface = sdl.getWindowSurface(window)


local rect = ffi.new('SDL_Rect', -100, 0, 100, 100)
local renderer = sdl.createRenderer(window, -1, sdl.RENDERER_ACCELERATED + sdl.RENDERER_PRESENTVSYNC)
sdl.setRenderDrawColor(renderer, 255, 255, 0, 0)

--local image = sdl.loadBMP("lena.bmp")
--sdl.upperBlit(image, nil, windowsurface, nil)
--sdl.updateWindowSurface(window)
--sdl.freeSurface(image)

local running = true
local event = ffi.new('SDL_Event')
while running do
	while sdl.pollEvent(event) ~= 0 do
		if event.type == sdl.QUIT then
			running = false
		end
	end

	sdl.renderFillRect(renderer, rect)
	if rect.x > 1280 then
		rect.x = -100
		rect.y = rect.y + 100
	else
		rect.x = rect.x + 10
	end
	sdl.renderPresent(renderer)

end

sdl.destroyWindow(window)
sdl.quit()
