function curry(f,g)
	return function(...)
		return f(g(...))
	end
end
