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

function ins2string(exp, namen)
	local t = {f=exp.f, o=exp.o, v=exp.v}
	local naam = namen[moes(exp)]
	for k,sub in subs(exp) do
		local naam = namen[moes(sub)]
		t[k] = X(naam or color.red..combineer(sub)..color.white)
	end
	assert(naam, 'naamloze exp: '..exp2string(exp))
	return naam .. '\t:= ' .. combineer(t)
end

local bieb = bieb()

local naam2moment = {
	-- looptijd
	['looptijd'] = set('init', 'itereer'),

	-- muis
	['muis.x'] = set('muis.beweegt', 'init'),
	['muis.y'] = set('muis.beweegt', 'init'),
	['muis.pos'] = set('muis.beweegt', 'init'),
	['muis.beweegt'] = set('muis.beweegt', 'init'),
	['muis.klik'] = set('muis.klik.begin', 'muis.klik.eind', 'init'),
	['muis.klik.begin'] = set('muis.klik.begin', 'init'),
	['muis.klik.eind'] = set('muis.klik.eind', 'init'),
	['muis.rechts'] = set('muis.klik.begin', 'muis.klik.eind', 'init'),
	['muis.rechts.begin'] = set('muis.klik.begin', 'init'),
	['muis.rechts.eind'] = set('muis.klik.begin', 'init'),
	['muis.klik.eind'] = set('muis.klik.eind', 'init'),

	-- toetsenbord
	['toets.neer'] = set('toets.neer.begin', 'toets.neer.eind'),
	['toets.neer.begin'] = 'toets.neer.begin',
	['toets.neer.eind'] = 'toets.neer.eind',

	-- std shit
	['stduit.schrijf'] = false,
	['niets'] = 'init',
	['_arg'] = 'test',
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

	-- geef alles een naam
	local maakvar = maakvars()
	local namen = {} -- moes → naam
	for sub in boompairsbfs(exp) do
		namen[moes(sub)] = maakvar()
	end

	local function dan(momenten, exp, strekking)
		for moment in pairs(momenten) do
			if strekking then
				moment = moment .. '.' .. strekking
			end

			assert(type(moment) == 'string', tostring(moment))
			assert(moment, 'geen moment voor '..combineer(exp))
			wanneer[moment] = wanneer[moment] or {}
			if wanneer[moment][moes(exp)] then
				return false
			end
			table.insert(wanneer[moment], exp)
			wanneer[moment][moes(exp)] = exp
		end
	end
	
	local maakvar = maakvars()

	-- exp, scope
	local function r(exp, strekking)

		-- functiemoment
		if fn(exp) == '_fn' then
			local moment = set(maakvar())
			dan(set'FUNC', exp, strekking)
			return 'FUNC'

		elseif atoom(exp) == '_arg' then
			dan(set'ARG', exp, strekking)
			return 'ARG'

		-- als dan
		elseif fn(exp) == '⇒' then

			local cond = arg0(exp) 
			local alsja = arg1(exp)
			local alsnee = arg2(exp)

			--r(arg1(exp))
			--if arg2(exp) then
--				r(arg2(exp))
			--end

			-- wanneer moet de conditie gebeuren
			local condtijd = r(arg0(exp))

			dan(condtijd, arg(exp))
			dan(condtijd, exp, strekking)

			-- wanneer moet de dan-tak gebeuren
			local alsjatijd = r(alsja, 'als.'..namen[moes(cond)])

			-- wanneer moet de anders-tak gebeuren
			if alsnee then
				local alsneetijd = r(alsnee, 'als.niet.'..namen[moes(cond)])
				--dan(alsneetijd, alsnee, strekking)
			end

			-- fake triplet
			--local triplet = X(',', cond, namen[alsja], namen[alsnee])
			--dan(condtijd, alsja)
			--dan(condtijd, namen[alsnee])
			--dan(condtijd, triplet)

			-- tijd van de hele if-statement
			return condtijd

		elseif isatoom(exp) then
			local momenten = ezmoment(exp)
			if type(momenten) ~= 'table' then
				momenten = set(momenten)
			end

			dan(momenten, exp, strekking)
			return momenten

		else

			-- kindermoment
			local momenten
			for k,sub in subs(exp) do
				local submomenten = r(sub)
				assert(submomenten, 'geen kindermoment voor '..combineer(sub))
				momenten = merge(momenten, submomenten)
			end

			assert(momenten, 'wat is het moment van '..combineer(exp))

			dan(momenten, exp, strekking)

			return momenten
		end
	end
	r(exp)

	print '=== FOCUSSTROOM ==='
	for moment,vals in pairs(wanneer) do
		print(moment..':')
		for i,val in ipairs(vals) do
			print('  '.. ins2string(val, namen))
		end
	end

	-- maak graaf ervan

	return wanneer
end
