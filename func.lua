function curry(f,g)
	return function(a)
		return f(g(a))
	end
end
