function magic()
	local m = {
		-- lists of others
		triggers = {
			-- no initial triggers
		},
		events = { 
			-- check
		},
		update = function () return end,
		val = nil,
		group = {'unknown'},
		name = '<unknown>',
		satis = true,
	}
	
	setmetatable(m, {
		__tostring = function () return magic2text(m) end,
		__index = function (t, v)
			if type(v) ~= 'string' then
				return indexed(m, v)
			end
		end,
	})
	
	return m
end

function trigger(magic)
	if magic.update then
		magic:update()
	end
	
	for kid,b in pairs(magic.events) do
		trigger(kid)
	end
end

function triggers(a, b)
	a.events[b] = true
	b.triggers[a] = true
	trigger(a)
end

function untriggers(a, b)
	a.events[b] = nil
	b.triggers[a] = nil
	trigger(a)
end
