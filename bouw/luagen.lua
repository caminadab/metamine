require 'func'

local unops = {
	['abs'] = 'math.abs($1)',
	['-'] = '- $1',
	['fn.eerste'] = '$1[1]',
	['fn.tweede'] = '$1[2]',
	['fn.derde'] = '$1[3]',
	['fn.vierde'] = '$1[4]',
}

local diops = {
	['plus'] = '$1 + $2',
	--['+'] = '$1 + $2',
	['·'] = '$1 * $2',
	['/'] = '$1 / $2',
}


function ins2lua(ins, focus)
	if fn(ins) == 'push' then
		focus = focus + 1
		assert(atoom(arg(ins)), unlisp(ins))
		return string.format('local %s = %s', varnaam(focus), atoom(arg(ins))), focus

	elseif fn(ins) == 'rep' then
		local res = {}
		local num = tonumber(atoom(arg(ins)))
		assert(num, unlisp(ins))
		for i = 1, num do
			res[#res+1] = string.format('local %s = %s', varnaam(focus+i), varnaam(tostring(focus)))
		end
		return table.concat(res, '\n'), focus + num

	elseif fn(ins) == 'wissel' then
		local naama = varnaam(focus)
		local num = atoom(arg(ins))
		local naamb = varnaam(focus + num)
		return string.format('local %s,%s = %s,%s', naama, naamb, naamb, naama), focus

	elseif unops[atoom(ins)] then
		local naam = varnaam(focus)
		local un = unops[atoom(ins)]:gsub('$1', naam)
		return string.format('local %s = %s', naam, un), focus

	elseif diops[atoom(ins)] then
		local naama = varnaam(focus-1)
		local naamb = varnaam(focus)
		local di = diops[atoom(ins)]:gsub('$1', naama):gsub('$2', naamb)
		return string.format('local %s = %s', naama, di), focus - 1

	else
		return '-- ' .. unlisp(ins), focus
	end
end

function luagen(sfc)
	local lijnen = {}
	lijnen[#lijnen+1] = 'local A = ...'
	local focus = 1
	for i,ins in ipairs(sfc) do
		lijnen[#lijnen+1], focus = ins2lua(ins, focus)
	end
	lijnen[#lijnen+1] = 'return A'
	return table.concat(lijnen, '\n')
end
