function A(argC) 
  local B = argC
  local C = 1
  local B = B[C+1]
  if B then
    local C = argC
    local D = 2
    local C = C[D+1]
    tmp = C
  end
  local C = tmp
  local D = argC
  local E = 0
  local D = D[E+1]
  local E = 0
  local D = D[E+1]
  local C = {C,D}
  local C = (function(alts) for i,alt in ipairs(alts) do if alt then return alt end end end)(C)
  local D = argC
  local E = 1
  local D = D[E+1]
  if D then
    local E = argC
    local F = 2
    local E = E[F+1]
    tmp = E
  end
  local E = tmp
  local F = argC
  local G = 0
  local F = F[G+1]
  local G = 1
  local F = F[G+1]
  local E = {E,F}
  local E = (function(alts) for i,alt in ipairs(alts) do if alt then return alt end end end)(E)
  local D = {D,E}
  local E = 2
  local F = 3
  local E = {[E]=true,[F]=true}
  local D = {D,E}
  return E
end
return A
