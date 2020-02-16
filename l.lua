local A = ...
function A(argB) 
  function B(argA) 
    local C = argA
    local D = 2
    local C = C * D
    return C,D
  end
  local C = 2
  local B = (function () local r = nil ; for i=1,C do r = B(r) end ; return r ; end)
  local C = argB
  local B = B(C)
  return B,C
end
A(3)
return A