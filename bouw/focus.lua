require 'graaf'
require 'combineer'
require 'bieb'
require 'exp'

function waarvoordfs(exp, fn)
	local res = {}
	local function r(exp)
		for k,sub in subs(exp) do	
			r(sub)
		end
		if fn(exp) then
			res[#res+1] = exp
		end
	end
	r(exp)
	return res
end

local muisinvoer = set(
	'muis.x', 'muis.y', 'muis.pos', 'muis.beweegt',
	'muis.klik', 'muis.klik.begin', 'muis.klik.eind'
)

local toetsenbordinvoer = set(
	'toets.neer', 'toets.neer.begin', 'toets.neer.eind'
)

local bieb = bieb()

-- codegen: focusstroom naar proc
-- focus: exp naar focusstroom
--  focusstroom : stroom(focus)
--    focus; lijst(exp)
function focus(exp)
	local focusgraaf = maakgraaf()
	local exps = {}

	-- constant(exp) -> init(schepper)
	local function isconstant(exp)
		if tonumber(atoom(exp)) or bieb[atoom(exp)] then
			exp.constant = true
			return true
		end
		local constant = false
		for k,sub in subs(exp) do
			if sub.constant then
				constant = true
			else
				constant = false
				break
			end
		end
		exp.constant = constant
		return constant
	end

	local function vindconstantenr(exp, t)
		if exp.constant and not bieb[atoom(exp)] or atoom(exp) == 'init' then
			t[#t+1] = exp
		else
			for k,sub in subs(exp) do
				vindconstantenr(sub, t)
			end
		end
	end

	local function vindconstanten(exp)
		local t = {}
		vindconstantenr(exp, t)
		return t
	end

	local function ismuis(exp)
		for k,sub in subs(exp) do
			if sub.ismuis then
				exp.ismuis = true
				return true
			end
		end
		exp.ismuis = muisinvoer[atoom(exp)]
		return exp.ismuis
	end

	local function vindmuizenr(exp, t)
		if exp.ismuis and not bieb[atoom(exp)] then
			t[#t+1] = exp
		else
			for k,sub in subs(exp) do
				vindmuizenr(sub, t)
			end
		end
	end

	local function vindmuizen(exp)
		local t = {}
		vindmuizenr(exp, t)
		return t
	end

	local function istoetsenbord(exp)
		return toetsenbordinvoer[atoom(exp)]
	end
	local function istimer(exp)
		return atoom(exp) == 'looptijd' or atoom(exp) == 'scherm.ververst'
	end

	waarvoordfs(exp, isconstant) -- markeer constantheid
	waarvoordfs(exp, ismuis) -- markeer constantheid
	local init = vindconstanten(exp)
	local muis = vindmuizen(exp) -- waarvoordfs(exp, ismuis)
	local toetsenbord = waarvoordfs(exp, istoetsenbord)
	local timer = waarvoordfs(exp, istimer)
	local mt = {__tostring = function (t) return table.concat(map(t,combineer), ', ') end}

	setmetatable(init, mt)
	setmetatable(muis, mt)
	setmetatable(toetsenbord, mt)
	setmetatable(timer, mt)
	
	focusgraaf:punt(init)
	if #muis > 0 then focusgraaf:link(init, muis) end
	if #timer > 0 then focusgraaf:link(init, timer) end
	if #toetsenbord > 0 then focusgraaf:link(init, toetsenbord) end

	--map(init, componeer(combineer, print))
	for i,v in ipairs(init) do print("INIT", combineer(v)) end
	for i,v in ipairs(muis) do print("MUIS", combineer(v)) end
	for i,v in ipairs(toetsenbord) do print("TOETSENBORD", combineer(v)) end
	for i,v in ipairs(timer) do print("TIMER", combineer(v)) end

	return focusgraaf
end

