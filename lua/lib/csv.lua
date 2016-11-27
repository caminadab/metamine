function csv_read(text)
	local res = {}
	text:gsub('(.-)\n?', function (line)
		local tr = {}
		line:gsub('([^,]*)', function (token)
			table.insert(tr, token)
		end)
		
		table.insert(res, tr)
	end)
	return res
end