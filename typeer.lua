require 'symbool'
require 'func'

local prios = {
	['^'] = 3, ['_'] = 3,
	['*'] = 2, ['/'] = 2,
	['+'] = 1, ['-'] = 1,
	['='] = 0,
}

local dichtbij = {['^']=true,['_']=true,['.']=true}
function leedwerk(exp, t)
	local prio = 0
	if isatoom(exp) then
		t[#t+1] = exp
	elseif exp[1] == '[]' then
		t[#t+1] = '['
		for i=2,#exp do
			leedwerk(exp[i], t)
			if next(exp,i) then
				t[#t+1] = ','
			end
		end
		t[#t+1] = ']'
	elseif #exp == 2 then
		leedwerk(exp[1], t)
		t[#t+1] = ' '
		leedwerk(exp[2], t)
	elseif #exp == 3 then
		leedwerk(exp[2], t)
		if not dichtbij[exp[1]] then t[#t+1] = ' ' end
		leedwerk(exp[1], t)
		if not dichtbij[exp[1]] then t[#t+1] = ' ' end
		leedwerk(exp[3], t)
	end
	return t
end

function leed(exp)
	local t = leedwerk(exp, {})
	return table.concat(t)
end

local function verenig_of(ta, tb)
	if ta == 'onbekend' then ta = nil end
	if tb == 'onbekend' then tb = nil end
	if ta and not tb then return ta end
	if tb and not ta then return tb end
	if not ta and not tb then return 'onbekend' end 
	if unlisp(ta) == unlisp(tb) then
		return ta
	end

	-- echte logica
	if tonumber(tb) then ta,tb = tb,ta end

	if tonumber(ta) and tonumber(tb) and ta ~= tb then
		return {'fout-ongelijkheid', ta, tb}
	end
	if tonumber(ta) and (tb == 'getal' or tb == 'int') then
		return tb
	end

	return 'onbekend'
end
assert(verenig_of('2', 'int') == 'int')

local function verenig_en(ta, tb)
	if ta == 'onbekend' then ta = nil end
	if tb == 'onbekend' then tb = nil end
	if ta and not tb then return ta end
	if tb and not ta then return tb end
	if not ta and not tb then return 'onbekend' end 
	if unlisp(ta) == unlisp(tb) then
		return ta
	end

	-- echte logica
	if tonumber(tb) then ta,tb = tb,ta end

	if tonumber(ta) and tonumber(tb) and ta ~= tb then
		return {'fout-ongelijkheid', ta, tb}
	end
	if tonumber(ta) and (tb == 'getal' or tb == 'int') then
		return ta
	end

	return nil
end
assert(verenig_en('2', 'int') == '2')

local vastetypen = {
	nu = 'moment',
	tau = 'getal',
	['toets-rechts'] = 	'getal',
	['toets-links'] =		'getal',
	['toets-omhoog'] = 	'getal',
	['toets-omlaag'] = 	'getal',
	['toets-spatie'] = 	'getal',
}

-- lengte of een lijst type
function lijstlen(t, typen)
	if isatoom(t) then return nil end
	if t[1] == '^' then return tostring(t[3]) end --TEMP tostring
end

-- gaat ervan uit dat typen.aantalOnbekend ingevuld is
function exptypeer(exp, typen)
	-- type van de expressie
	local t
	if isatoom(exp) then
		if typen[exp] then
			t = typen[exp]
		elseif tonumber(exp) then
			t = 'getal'
		end
	else
		if exp[1] == '=' then
			local a,b = exp[2], exp[3]
			local ta,tb = exptypeer(a, typen), exptypeer(b, typen)
			t = verenig_en(ta,tb)
			if not t then
				t = {'fout-ongelijk', ta, tb}
			end
			--print('T', leed(ta), leed(tb), leed(t))
			-- t = verenig(ta, tb)
			--typen[a] = t
			--typen[b] = t
		end

		if exp[1] == '+' or exp[1] == '*' or exp[1] == '/' or exp[1] == '-' then
			local a,b = exp[2], exp[3]
			local ta,tb = exptypeer(a, typen), exptypeer(b, typen)
			t = 'fout-lijst-lengte-discrepantie'
			
			-- elementswijs
			local la, lb = lijstlen(ta), lijstlen(tb)
			if la and lb then
				if la == lb then
					t = {'^', verenig_of(ta[2], tb[2]), ta[3]}
					typen[exp] = t
				else
					print(type(la), type(lb))
					print("!", leed(la), leed(lb))
				end
			end

			-- automagie
			if lb and not la then
				la,lb = lb,la
				ta,tb = tb,ta
			end
			-- [0,1] + 0
			-- ta: getal^2, tb: getal
			if la and not lb then
				t = {'^', verenig_of(ta[2], tb), ta[3]}
			end
		end	

		if exp[1] == '[]' then
			local ti = nil
			for i=2,#exp do
				local a = exp[i]
				local ta = exptypeer(a, typen)
				ti = verenig_of(ti, ta)
				-- t
			end
			t = {'^', ti, #exp-1}
			
		end

		-- zit hij erin?
		if typen[exp[1]] then
			local ft = typen[exp[1]] -- functie type
			if isatoom(ft) then
				typen[exp] = {'fout-is-geen-functie', ft}
				return typen[exp]
			else

				-- lijsten
				if ft[1] == '^' then
					-- index
					if ft[3] == 'int' then
						typen[exp[2]] = 'int'
					else
						typen[exp[2]] = {'..', 0, ft[3]}
					end
					t = ft[2]
				end

				-- functies
				if ft[1] == '->' then
					local van,naar = ft[2],ft[3]
					typen[exp[2]] = van
					t = naar
				end
			end
		end
	end

	if not t then return typen[exp] end
	if not typen[exp] then typen[exp] = t; return t end

	typen[exp] = verenig_en(t, typen[exp])

	--print(leed(t)..' & '..leed(typen[exp])..' => '..leed(typen[exp]))

	typen.aantalOnbekend = typen.aantalOnbekend + 1
	return t
end

-- invoer: _G.print_typen
function typeer(feiten,typen)
	local typen = typen or {aantalOnbekend = 0}
	local fouten = {}
	local vroegerOnbekend = 999999

	-- zoek types
	for i,feit in ipairs(feiten) do
		if isexp(feit) and feit[1] == ':' then
			typen[feit[2]] = feit[3]
		end
	end

	local feiten = filter(feiten, function (feit) return isexp(feit) and feit[1] == '=' end)
	while true do
		typen.aantalOnbekend = 0
	
		for i, feit in ipairs(feiten) do
			local type = exptypeer(feit, typen)
		end

		if typen.aantalOnbekend == vroegerOnbekend then
			break
		end
		vroegerOnbekend = typen.aantalOnbekend
	end

	if print_typen then
		for naam,type in spairs(typen) do
			if naam ~= 'aantalOnbekend' then
				print(leed(naam)..': '..leed(type))
			end
		end
		print()
	end

	if typen.aantalOnbekend > 0 then
		for k,v in spairs(typen) do
			if v == 'onbekend' then
				print('ONBEKEND:',leed(k))
			end
		end
		--error('onbekende types')
	end

	return typen, fouten
end
