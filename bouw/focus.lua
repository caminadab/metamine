require 'graaf'
require 'combineer'
require 'util'
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

local bieb = bieb()

-- codegen: focusstroom naar proc
-- focus: exp naar focusstroom
--  focusstroom : stroom(focus)
--    focus; lijst(exp)
function focus2(exp)
	local focusgraaf = maakgraaf()
	local exps = {}

	-- constant(exp) -> init(schepper)
	local function isconstant(exp)
		if tonumber(atoom(exp)) or (bieb[atoom(exp)] and atoom(exp) ~= 'looptijd')  then
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

	return focusgraaf
end

local naam2moment = {
	-- looptijd
	['looptijd'] = 'itereer',

	-- muis
	['muis.x'] = 'muis.beweegt',
	['muis.y'] = 'muis.beweegt',
	['muis.pos'] = 'muis.beweegt',
	['muis.beweegt'] = 'muis.beweegt',
	['muis.klik'] = set('muis.klik.begin', 'muis.klik.eind'),
	['muis.klik.begin'] = 'muis.klik.begin',
	['muis.klik.eind'] = 'muis.klik.eind',

	-- toetsenbord
	['toets.neer'] = set('toets.neer.begin', 'toets.neer.eind'),
	['toets.neer.begin'] = 'toets.neer.begin',
	['toets.neer.eind'] = 'toets.neer.eind',

	-- std shit
	['stduit.schrijf'] = false,
}

local function merge(a, b)
	if not a and not b then return nil end
	if not a then return b end
	if not b then return a end
	if type(a) == 'string' and type(b) == 'string' then
		return set(a,b)
	end
	if type(a) == 'string' then a,b = b,a end
	if type(b) == 'string' then
		a[b] = true
		return a
	end
	for k in pairs(b) do
		a[k] = true
	end
	return a
end

function ezmoment(exp)
	if naam2moment[atoom(exp)] then return naam2moment[atoom(exp)] end
	if bieb[atoom(exp)] then return 'init' end
	if atoom(exp) == 'niets' then return 'init' end
	if tonumber(atoom(exp)) then return 'init' end
end

function focus(exp)
	local momenten = {}

	local function dan(moment, exp)
		assert(type(moment) == 'string')
		assert(moment, 'geen moment voor '..combineer(exp))
		momenten[moment] = momenten[moment] or {}
		table.insert(momenten[moment], exp)
	end

	local function r(exp)

		if isatoom(exp) then
			local momenten = ezmoment(exp)

			if type(momenten) == 'string' then
				dan(momenten, exp)
			else
				for moment in pairs(momenten) do
					dan(moment, exp)
				end
			end
			return momenten

		else

			local momenten
			for k,sub in subs(exp) do
				momenten = merge(momenten, r(sub))
			end
			--assert(moment, 'wat is het moment van '..combineer(exp))

			if type(momenten) == 'string' then
				dan(momenten, exp)
			else
				for moment in pairs(momenten) do
					dan(moment, exp)
				end
			end
			return momenten
		end
	end
	r(exp)

	for k,v in pairs(momenten) do
		print('WANNEER', k)
		for i,v in ipairs(v) do
			print('  DAN', combineersimpel(v, 2))
		end
	end

	return 2
end
