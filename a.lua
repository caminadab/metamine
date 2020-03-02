local cache = {}
local A = 2
local B = 1
local A = A > B
cache[0] = A
local A = not A
if A then
  local A = 1
  local B = 2
  local A = A / B
  tmp = A
end
local A = tmp
local B = cache[0]
if B then
  local B = 0
  tmp = B
end
local B = tmp
local A = {A,B}
local A = (function(alts) for i,alt in ipairs(alts) do if alt then return alt end end end)(A)
local B = 1
local C = 2
local B = B / C
cache[1] = B
local A = A + B
local B = cache[1]
local A = A + B
return A
