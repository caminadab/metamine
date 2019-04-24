local meta = {}

function meta:__newindex(index,waarde)
	local s = self.s
	if waarde == nil then
		if s[index] then
			s[index][waarde] = false
			if next(s[index]) == nil then
				s[index] = nil
			end
		end
	else
		s[index] = s[index] or {}
		s[index][waarde] = true
	end
end

function meta:__index(index)
	return self.s[index] or {}
end

function meta:__pairs()

  -- Iterator function takes the table
	-- and an index and returns the next index and associated value
  -- or nil to end iteration

	-- tabel, index
	--local t,tk

	-- mk: {k, v}: sleutel, set van waarden, waarde
	local v = nil

  local function stateless_iter(self, k)
		local self = self.s
		if k == nil then
			local s
			k,s = next(self)
			if k then
				assert(next(s))
				v = next(s)
				return k, v
			else
				return nil
			end
		else
			v = next(self[k], v)
			
			-- nieuwe key
			if not v then
				local s
				k,s = next(self, k)
				if k then
					assert(next(s))
					v = next(s)
					return k, v
				else
					return nil
				end
			end

			return k,v
		end
  end

  -- Return an iterator function, the table, starting point
  return stateless_iter, self, nil
end

function mmap()
	local t = {s = {}}
	setmetatable(t, meta)
	return t
end
