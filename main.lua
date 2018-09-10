package.path = package.path .. ';../?.lua'
local function agg(...)
	-- functies
	local a = {...}
	--local r = {}
	for i,v in ipairs(a) do
		if v then return v end
		--r[v] = true
		-- conditie, feit
		--local c,f = v[2],v[3]
		--r[c] = f
	end
	return false
end
local function tot(a,b)
	local r = {}
	local j = 0
	for i=a,b-1 do
		r[j] = i
		j = j + 1
	end
	return r
end

local function len(a) return #a+1 end
local function en(a,b) return a and b end
local function of(a,b) return a or b end
local function niet(a) return not a end

local function plus(a,b) if tonumber(a) and tonumber(b) then return a + b end end
local function keer(a,b) if tonumber(a) and tonumber(b) then return a * b end end

local function combineer(a,b)
	if a and b and a ~= b then error('meerdere waarden passen niet in enkele variabele: '..tostring(a)..' en '..tostring(b)) end
	if b then return b end
	if a then return a end
	return nil
end

local function index(a,b)
	return a[b]
end

local function som(a)
	local som = 0
	for i,v in pairs(a) do
		som = som + v
	end
	return som
end
local function sincos(hoek)
	return {[0]=math.cos(hoek), math.sin(hoek)}
end

local function dan(cond,v)
	if cond then
		return v
	else
		return nil
	end
end

local function eq(a,b)
	if type(a) == 'number' and type(b) == 'number' then
		return math.abs(a-b) < 1e-3
	else
		return a == b
	end
end
local bag = {}
local function var(ass)
	for cond in pairs(ass) do
		if cond then
			bag[ass] = cond
			return cond
		end
	end
	return bag[ass] or 0
end
VROEGER = 0
start = love.timer.getTime()
nu = start

toetsRechts = { }
for i=0,599 do toetsRechts[i] = 0 end
local toetsRechtsAan = 0
local toetsRechtsUit = 0
toetsLinks = { }
for i=0,599 do toetsLinks[i] = 0 end
local toetsLinksAan = 0
local toetsLinksUit = 0
toetsOmhoog = { }
for i=0,599 do toetsOmhoog[i] = 0 end
local toetsOmhoogAan = 0
local toetsOmhoogUit = 0
toetsOmlaag = { }
for i=0,599 do toetsOmlaag[i] = 0 end
local toetsOmlaagAan = 0
local toetsOmlaagUit = 0
toetsSpatie = { }
for i=0,599 do toetsSpatie[i] = 0 end
local toetsSpatieAan = 0
local toetsSpatieUit = 0
toetsA = { }
for i=0,599 do toetsA[i] = 0 end
local toetsAAan = 0
local toetsAUit = 0
toetsS = { }
for i=0,599 do toetsS[i] = 0 end
local toetsSAan = 0
local toetsSUit = 0
toetsD = { }
for i=0,599 do toetsD[i] = 0 end
local toetsDAan = 0
local toetsDUit = 0
toetsF = { }
for i=0,599 do toetsF[i] = 0 end
local toetsFAan = 0
local toetsFUit = 0
toetsH = { }
for i=0,599 do toetsH[i] = 0 end
local toetsHAan = 0
local toetsHUit = 0
toetsJ = { }
for i=0,599 do toetsJ[i] = 0 end
local toetsJAan = 0
local toetsJUit = 0
toetsK = { }
for i=0,599 do toetsK[i] = 0 end
local toetsKAan = 0
local toetsKUit = 0
toetsL = { }
for i=0,599 do toetsL[i] = 0 end
local toetsLAan = 0
local toetsLUit = 0
local prevSpaceDown = false

local toetsSpatieAan = false
local toetsSpatieUit = false
function love.update()
for i=0,600-1 do toetsRechts[i] = toetsRechts[i+1] or 0 end
toetsRechts[600] = (love.keyboard.isDown("right") and 1/60 or 0)
for i=0,600-1 do toetsLinks[i] = toetsLinks[i+1] or 0 end
toetsLinks[600] = (love.keyboard.isDown("left") and 1/60 or 0)
for i=0,600-1 do toetsOmhoog[i] = toetsOmhoog[i+1] or 0 end
toetsOmhoog[600] = (love.keyboard.isDown("up") and 1/60 or 0)
for i=0,600-1 do toetsOmlaag[i] = toetsOmlaag[i+1] or 0 end
toetsOmlaag[600] = (love.keyboard.isDown("down") and 1/60 or 0)
for i=0,600-1 do toetsSpatie[i] = toetsSpatie[i+1] or 0 end
toetsSpatie[600] = (love.keyboard.isDown("space") and 1/60 or 0)
for i=0,600-1 do toetsA[i] = toetsA[i+1] or 0 end
toetsA[600] = (love.keyboard.isDown("a") and 1/60 or 0)
for i=0,600-1 do toetsS[i] = toetsS[i+1] or 0 end
toetsS[600] = (love.keyboard.isDown("s") and 1/60 or 0)
for i=0,600-1 do toetsD[i] = toetsD[i+1] or 0 end
toetsD[600] = (love.keyboard.isDown("d") and 1/60 or 0)
for i=0,600-1 do toetsF[i] = toetsF[i+1] or 0 end
toetsF[600] = (love.keyboard.isDown("f") and 1/60 or 0)
for i=0,600-1 do toetsH[i] = toetsH[i+1] or 0 end
toetsH[600] = (love.keyboard.isDown("h") and 1/60 or 0)
for i=0,600-1 do toetsJ[i] = toetsJ[i+1] or 0 end
toetsJ[600] = (love.keyboard.isDown("j") and 1/60 or 0)
for i=0,600-1 do toetsK[i] = toetsK[i+1] or 0 end
toetsK[600] = (love.keyboard.isDown("k") and 1/60 or 0)
for i=0,600-1 do toetsL[i] = toetsL[i+1] or 0 end
toetsL[600] = (love.keyboard.isDown("l") and 1/60 or 0)
	-- update toets
	toetsSpatieAan = false
	toetsSpatieUit = false

	if love.keyboard.isDown("space") and prevSpaceDown == false then
		prevSpaceDown = true
		toetsSpatieAan = true
	elseif not love.keyboard.isDown("space") and prevSpaceDown == true then
		prevSpaceDown = false
		toetsSpatieUit = true
	end
stip2 = sincos(nu)
stip1 = sincos(stip2)
stip0_0 = keer(100, stip1[0])
stip0_1 = keer(100, stip1[1])
stip_0 = plus(100, stip0_0)
stip_1 = plus(100, stip0_1)
stip = {[0] = stip_0, stip_1}
schaduw_stip2 = stip2
schaduw_stip1 = stip1
schaduw_stip0_0 = stip0_0
schaduw_stip0_1 = stip0_1
schaduw_stip_0 = stip_0
schaduw_stip_1 = stip_1
schaduw_stip = stip
		nu = love.timer.getTime()
		beeld = nu
	end
local lgsc = love.graphics.setColor
love.graphics.setColor = function(r,g,b,a)
	local a = a or 1
	lgsc(r*255,g*255,b*255,a*255)
	--lgsc(254,255,255,255)
end

function love.draw()
	if stip and stip[0] and stip[1] then
		love.graphics.circle('fill', stip[0], stip[1], stip[2] or 20)
	end
love.graphics.print("stip = 100 + 100 * sincos (sincos nu)\
\
\
", 500, 10)
	local sx,sy = 10,310
	local x,y = sx,sy
	love.graphics.setLineJoin('none')

	function grafiek(lijst,sx,sy,w,h)
		local w = w or 600--#lijst
		local h = h or 20
		local xsch = 1
		local ysch = 1
		--local vx,vy = xsch*0, lijst[1]*ysch
		local p = {}
		local vx,vy
		for i=1,#lijst do
			local x = xsch * i
			local y = ysch * lijst[i]
			local bx,by = sx+x, sy+h - y*h*60

			-- horiz
			if vy ~= by or i == 1 or i == 600 then
				p[#p+1] = (vx or bx)
				p[#p+1] = (vy or by)
				p[#p+1] = bx
				p[#p+1] = by
			end
			vx,vy = bx,by
		end

		love.graphics.setLineStyle('rough')
		if #p < 2 then
			love.graphics.print('niet genoeg data',sx,sy)
		else
			love.graphics.line(p)
		end
	end

	-- grafieken
	love.graphics.setColor(0,.05*1,1) grafiek(toetsRechts, 20, 120+10*1,100,6)
love.graphics.setColor(0,.05*2,1) grafiek(toetsLinks, 20, 120+10*2,100,6)
love.graphics.setColor(0,.05*3,1) grafiek(toetsOmhoog, 20, 120+10*3,100,6)
love.graphics.setColor(0,.05*4,1) grafiek(toetsOmlaag, 20, 120+10*4,100,6)
love.graphics.setColor(0,.05*5,1) grafiek(toetsSpatie, 20, 120+10*5,100,6)
love.graphics.setColor(0,.05*6,1) grafiek(toetsA, 20, 120+10*6,100,6)
love.graphics.setColor(0,.05*7,1) grafiek(toetsS, 20, 120+10*7,100,6)
love.graphics.setColor(0,.05*8,1) grafiek(toetsD, 20, 120+10*8,100,6)
love.graphics.setColor(0,.05*9,1) grafiek(toetsF, 20, 120+10*9,100,6)
love.graphics.setColor(0,.05*10,1) grafiek(toetsH, 20, 120+10*10,100,6)
love.graphics.setColor(0,.05*11,1) grafiek(toetsJ, 20, 120+10*11,100,6)
love.graphics.setColor(0,.05*12,1) grafiek(toetsK, 20, 120+10*12,100,6)
love.graphics.setColor(0,.05*13,1) grafiek(toetsL, 20, 120+10*13,100,6)
	love.graphics.setColor(1,1,1)
	love.graphics.reset()

	-- framerate
	local w
	if love.graphics.getWidth then w = love.graphics.getWidth()
	else w = love.window.getWidth() end
	love.graphics.print(tostring(love.timer.getFPS()), w - 30, 10)
end