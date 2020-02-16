local A = ...
function A(argA) 
  local B = argA
  local C = 1
  local B = B[C+1]
  local C = 0
  local B = B and C
  local C = argA
  local D = 0
  local C = C[D+1]
  local D = 0
  local C = C[D+1]
  local B = {B,C}
  local B = (function(alts) for i,alt in ipairs(alts) do if v then return v end end end)(B)
  local B = {B}
  local C = argA
  local D = 1
  local C = C[D+1]
  local D = 0
  local C = C and D
  local D = argA
  local E = 0
  local D = D[E+1]
  local E = 0
  local D = D[E+1]
  local C = {C,D}
  local C = (function(alts) for i,alt in ipairs(alts) do if v then return v end end end)(C)
  local C = - C
  local B = {B,C}
  return B
end
return A
