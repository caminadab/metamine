require 'symbool'

-- set unie
function unie(a,b)
	local r = {}
	for x in pairs(a) do r[x] = true end
	for x in pairs(b) do r[x] = true end
	return r
end

function wanneer1(exp)
	if exp:sub(1,6) == 'toets-' then
		local toets = exp
		return {[toets..'-aan']=true, [toets..'-uit']=true}
	end
	if tonumber(exp) then
		return {['start']=true}
	end
	return 'onbekend'
end

function waneer(exp)
	if isatoom(exp) then
	end
end

function set2tekst(set)
	local t = { '{' }
	for x in pairs(set) do
		t[#t+1] = x
		if next(set,x) then
			t[#t+1] = ', '
		end
	end
	t[#t+1] = '}'
	return table.concat(t)
end

function plan(stroom)
	return stroom
end

function plan0(stroom)
	local plan = {} -- tijdstip -> assignments
	local tijd = {}
	for i,eq in ipairs(stroom) do
		local naam,exp = eq[2],eq[3]
		local afh = var(exp)
		local tijdstip = {}

		--[[for bron in pairs(afh) do
			local tijdstip0 = tijd[bron] or wanneer(bron)
			print('bron', bron, set2tekst(tijdstip0))
			tijdstip = unie(tijdstip, tijdstip0)
		end]]

		tijd[naam] = tijdstip
		--print('tijd', naam, tijdstip, leed(eq))
		plan[tijdstip] = plan[tijdstip] or {}
		table.insert(plan[tijdstip], eq)

	end
	return plan
end

-- tests
