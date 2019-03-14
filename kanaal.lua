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
local int = 'int'
local getal = 'getal'
local _istype = function(a,b)
    if b == getal then return type(a) == 'number' end
    if b == int then return type(a) == 'number' and a%1 == 0 end
    if b == lijst then return type(a) == 'table' end
    return false
end
local _comp = function(a,b)
    return function(...)
        return b(a(...))
    end
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

local D = tabel{104,111,105}
local E = tabel{104,111,101}
local F = tabel{105,115}
local G = tabel{104,101,116}
local H = tabel{100,97,110}
local C = tabel{D,E,F,G,H}
local J = function (_A)
    local L = tabel{}
    local M = function (_B)
        local P = #(_B)
        local O = tabel{P}
        local N = cat{O, _B}
        return N
    end
    for i=1,#_A do
        L[i] = M(_A[i])
    end
    local K = cat(L)
    return K
end
local Q = function (_C)
    local U = tabel{}
    local T = tabel{_C,U}
    local W = function (_D)
        local Z = _D(0)
        local CB = _D(0)
        local BB = CB(0)
        local AB = 1 + BB
        local Y = vanaf(Z,AB)
        local EB = _D(1)
        local HB = _D(0)
        local LB = _D(0)
        local KB = LB(0)
        local JB = 1 + KB
        local IB = tabel{1,JB}
        local GB = deel(HB,IB)
        local FB = tabel{GB}
        local DB = cat{EB, FB}
        local X = tabel{Y,DB}
        return X
    end
    local V = _pow(W,9)
    local S = V(T)
    local R = S(1)
    return R
end
local I = _comp(J,Q)
local B = I(C)
local MB = tabel{44}
local A = cat(B,MB)
print(string.char(unpack(A)))
