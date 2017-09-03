local insert = table.insert
local remove = table.remove
local unpack = table.unpack
local concat = table.concat
local find = string.find
local floor = math.floor

function clone(sexp)
	if atom(sexp) then
		return sexp
	else
		local res = {}
		for i,v in ipairs(sexp) do
			res[i] = clone(v)
		end
		return res
	end
end

function isnumber(sexp)
	return tonumber(sexp)
end
function istext(sexp)
	return atom(sexp) and sexp:sub(1,1)=="'" and sexp:sub(-1)=="'"
end
function isname(sexp)
	return atom(sexp) and string.match(sexp:sub(1,1), '%a')
end

-- 1 + 2 + 3 + 4 -> (+ 1 2 3 4)
function multi(sexp, op)
	sexp = clone(sexp)
	local res = {op}
	local cur = sexp
	while cur[1] == op do
		insert(res, 2, cur[3])
		cur = cur[2]
	end
	-- laatste
	insert(res, 2, cur)
	return res
end

-- (+ 1 2 3 4) -> 1 + 2 + 3 + 4
function unmulti(sexp)
	local op = sexp[1]
	if #sexp == 2 then
		return sexp[2]
	else
		local cur = {op, sexp[2], sexp[3]}
		for i=4,#sexp do
			cur = {op, cur, sexp[i]}
		end
		return cur
	end
end

