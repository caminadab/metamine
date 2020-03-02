local cache = {}
function A(argD) 
  local B = argD
  cache[0] = B
  cache[1] = B
  local C = 1
  local B = B[C+1]
  if B then
    local B = false
    tmp = B
  end
  local B = tmp
  local C = argD
  local D = 12
  local C = C[D+1]
  if C then
    local C = true
    tmp = C
  end
  local C = tmp
  local D = argD
  local E = 13
  local D = D[E+1]
  if D then
    local D = false
    cache[2] = D
    cache[3] = D
    tmp = D
  end
  local D = tmp
  local E = argD
  local F = 0
  local E = E[F+1]
  local F = 0
  local E = E[F+1]
  local B = {B,C,D,E}
  local B = (function(alts) for i,alt in ipairs(alts) do if alt then return alt end end end)(B)
  local C = cache[0]
  local D = cache[1]
  local C = C[D+1]
  if C then
    local C = argD
    local D = 2
    local C = C[D+1]
    tmp = C
  end
  local C = tmp
  local D = cache[2]
  local E = cache[3]
  local D = D[E+1]
  local E = 1
  local D = D[E+1]
  local C = {C,D}
  local C = (function(alts) for i,alt in ipairs(alts) do if alt then return alt end end end)(C)
  local D = cache[0]
  local E = cache[1]
  local D = D[E+1]
  if D then
    local D = {}
    tmp = D
  end
  local D = tmp
  local E = argD
  local F = 6
  local E = E[F+1]
  if E then
    local E = argD
    local F = 0
    local E = E[F+1]
    local F = 2
    local E = E[F+1]
    local F = argD
    local G = 5
    local F = F[G+1]
    local F = {[F]=true}
    local E = (function(a,b) local r = {}; for i in pairs(a) do r[i] = true end ; for i in pairs(b) do r[i] = true end ; return r ; end)(E,F)
    tmp = E
  end
  local E = tmp
  local F = argD
  local G = 7
  local F = F[G+1]
  if F then
    local F = argD
    local G = 0
    local F = F[G+1]
    local G = 2
    local F = F[G+1]
    local G = argD
    local H = 5
    local G = G[H+1]
    local G = {[G]=true}
    local F = (function(a,b) local r = {}; for i in pairs(a) do if not b[i] then r[i] = true end end return r ; end)(F,G)
    tmp = F
  end
  local F = tmp
  local G = cache[2]
  local H = cache[3]
  local G = G[H+1]
  local H = 2
  local G = G[H+1]
  local D = {D,E,F,G}
  local D = (function(alts) for i,alt in ipairs(alts) do if alt then return alt end end end)(D)
  local E = cache[0]
  local F = cache[1]
  local E = E[F+1]
  if E then
    local E = 1
    local F = 0
    local E = E / F
    local F = 1
    local G = 0
    local F = F / G
    local E = {E,F}
    tmp = E
  end
  local E = tmp
  local F = argD
  local G = 10
  local F = F[G+1]
  if F then
    local F = argD
    local G = 11
    local F = F[G+1]
    tmp = F
  end
  local F = tmp
  local G = cache[2]
  local H = cache[3]
  local G = G[H+1]
  local H = 3
  local G = G[H+1]
  local E = {E,F,G}
  local E = (function(alts) for i,alt in ipairs(alts) do if alt then return alt end end end)(E)
  local B = {B,C,D,E}
  local C = 1
  local B = {B,C}
  return B
end
return A
