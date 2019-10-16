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

function ins2string(exp, exps)
	local t = {f=exp.f, o=exp.o, v=exp.v}
	local naam = exps[exp]
	for k,sub in subs(exp) do
		local naam = exps[sub]
		assert(naam, 'naamloze exp: '..exp2string(sub))
		t[k] = X(naam)
	end
	local naam = exps[exp]
	assert(naam, 'naamloze exp: '..exp2string(exp))
	return naam .. '\t:= ' .. combineer(t)
end

local bieb = bieb()

local naam2moment = {
	-- looptijd
	['looptijd'] = set('init', 'itereer'),

	-- muis
	['muis.x'] = 'muis.beweegt',
	['muis.y'] = 'muis.beweegt',
	['muis.pos'] = 'muis.beweegt',
	['muis.beweegt'] = 'muis.beweegt',
	['muis.klik'] = set('muis.klik.begin', 'muis.klik.eind', 'init'),
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
	error('onbekend moment voor '..combineer(exp))
end

function focus(exp)
	local wanneer = {} -- moment → exps, moment → (moes → moment)

	local function dan(moment, exp)
		assert(type(moment) == 'string')
		assert(moment, 'geen moment voor '..combineer(exp))
		wanneer[moment] = wanneer[moment] or {}
		if wanneer[moment][moes(exp)] then
			return false
		end
		table.insert(wanneer[moment], exp)
		wanneer[moment][moes(exp)] = exp
	end
	
	local maakvar = maakvars()

	local function r(exp)

		-- kindermoment
		local momenten
		for k,sub in subs(exp) do
			local submomenten = r(sub)
			assert(submomenten, 'geen kindermoment voor '..combineer(sub))
			momenten = merge(momenten, submomenten)
		end

		-- functiemoment
		if fn(exp) == '_fn' then
			local moment = maakvar()
			dan('FUNC', exp)
			return 'FUNC'

		elseif atoom(exp) == '_arg' then
			dan('ARG', exp)
			return 'ARG'

		elseif fn(exp) == '⇒' then
			--error'OK'
			local moment = maakvar()
			dan(moment, exp)
			return 'DAN'

		elseif isatoom(exp) then
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

			assert(momenten, 'wat is het moment van '..combineer(exp))

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

	local exps = {}
	print '=== FOCUSSTROOM ==='
	for k,vals in pairs(wanneer) do
		print(k..':')
		for i,val in ipairs(vals) do
			exps[val] = maakvar()
			print('  '.. ins2string(val, exps))
		end
	end

	-- maak graaf ervan

	return wanneer
end
