local tau = math.pi * 2
local ja = true
local nee = false
local pack = pack or table.pack
local unpack = unpack or table.unpack
local _pow = function(a,b)
    if type(a) == 'number' then
        return a ^ b
    else
        return function(c)
            for i=1,b do
                c = a(c)
            end
            return c
        end
    end
end
local lijst = 'lijst'
local getal = function(a)
    return tonumber(string.char(table.unpack(a)))
end
local int = function(a)
    local getal
    if type(a) == 'number' then
        getal = a
    else
        getal = tonumber(string.char(table.unpack(a)))
    end
    if not getal then return false end
    return math.floor(getal)
end;
local _iinterval = function(a,b)
    local t = {}
    for i = 1,#b-1 do
        t[i] = b
    end
    return t
end;
local _istype = function(a,b)
    if b == getal then return type(a) == 'number' end
    if b == int then return type(a) == 'number' and a%1 == 0 end
    if b == lijst then return type(a) == 'table' end
    -- set dan maar
    return not not b[a]
    --return false
end
local _procent = function(n) return n / 100 end
local _comp = function(a,b)
    return function(...)
        return b(a(...))
    end
end
local javascript = function(broncode)
    -- ^_^
    require 'bieb'
    return bieb.javascript(broncode)
end
local tabel = function(t)
    local t = t or {}
    local mt = {}
    function mt:__call(i)
        return t[i+1]
    end
    setmetatable(t, mt)
    return t
end
local vanaf = function(a,van)
    local t = tabel{}
    for i=van+1,#a do
        t[#t+1] = a[i]
    end
    return t
end

local tot = function(a,tot)
    local t = tabel{}
    for i=1,tot do
        t[#t+1] = a[i]
    end
    return t
end

local deel = function(a,b)
    local van,tot = b[1],b[2]
    local t = tabel{}
    for i=van+1,tot do
        t[#t+1] = a[i]
    end
    return t
end

local _kies = function(a,b)
    local fa = type(a) == 'function'
    local fb = type(b) == 'function'
    if a and b then return 'fout' end
    return a or b
end

local cat = function(a,b)
    local r = tabel{}
    for i,v in ipairs(a) do
        for i,v in ipairs(v) do
            r[#r+1] = v
        end
        if b and i ~= #a then
            for i,b in ipairs(b) do
                r[#r+1] = b
            end
        end
    end
    return r
end

local vind = function(a,b)
    for i=1,#a-#b+1 do
        local gevonden = true
        for j=i,i+#b-1 do
            if a[j] ~= b[j-i+1] then
                gevonden = false
                break
            end
        end
        if gevonden then
            return i-1
        end
    end
    return false
end

local tekst = function (a)
    local t = tostring(a)
    return {string.byte(t,1,#t)}
end

local herhaal = function(f)
    return function(a)
        local r = a
        while a do
            r = a
            a = f(a)
        end
        return r
    end
end

local D = _iinterval(1,1000)
local E = function (_A)
    local H = _A % 3
    local G = H == 0
    local J = _A % 5
    local I = J == 0
    local F = G and I
    return F
end
local C = filter(D,E)
local B = som(C)
local A = tekst(B)
return A