local A = ...
local B = A
print("local B = A")
print(B)
local C = B
print("local C = B")
print(C)
local D = C
print("local D = C")
print(D)
local E = D
print("local E = D")
print(E)
local F = E
print("local F = E")
print(F)
local F = function(x) return x end
print("local F = function(x) return x end")
print(F)
local F,E = E,F
print("local F,E = E,F")
print(F)
local F = 1
print("local F = 1")
print(F)
local F = function(x) return F end
print("local F = function(x) return F end")
print(F)
local E = function(x) return {E(x), F(x)} end
print("local E = function(x) return {E(x), F(x)} end")
print(E)
local E,D = D,E
print("local E,D = D,E")
print(E)
local E = function(x) return x[1] + x[2] end
print("local E = function(x) return x[1] + x[2] end")
print(E)
local D = function(x) return E(D(x)) end
print("local D = function(x) return E(D(x)) end")
print(D)
local D,C = C,D
print("local D,C = C,D")
print(D)
local D = 2
print("local D = 2")
print(D)
local C = (function (f,n) for i=1,n do r = f(r) end ; return r; end)(C,D)
print("local C = (function (f,n) for i=1,n do r = f(r) end ; return r; end)(C,D)")
print(C)
local C,B = B,C
print("local C,B = B,C")
print(C)
local C = 3
print("local C = 3")
print(C)
local B = B(C)
print("local B = B(C)")
print(B)
local B,A = A,B
print("local B,A = A,B")
print(B)
local C = B
print("local C = B")
print(C)
local C = 2
print("local C = 2")
print(C)
local C,B = B,C
print("local C,B = B,C")
print(C)
local C = 3
print("local C = 3")
print(C)
local B = B ^ C
print("local B = B ^ C")
print(B)
local A = A + B
print("local A = A + B")
print(A)
return A
