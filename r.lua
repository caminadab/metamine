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

local tekst = function (a)
    local t = tostring(a)
    return pack(string.byte(t,1,#t))
end

local C = tabel{2}
local B = tabel{1,C,3}
local E = function (_C)
    local F = tabel{}
    return F
end
local H = function (_B)
    local I = function (_A)
        local L = _istype(_A,lijst)
        local K = false
        if L then
            local O = tabel{108}
            local Q = tabel{}
            for i=1,#_A do
                Q[i] = _B(_A[i])
            end
            local P = cat(Q)
            local N = cat{O, P}
            local R = tabel{101}
            local M = cat{N, R}
            K = M
        end
        local T = _istype(_A,int)
        local S = false
        if T then
            local W = tabel{105}
            local X = tekst(_A)
            local V = cat{W, X}
            local Y = tabel{101}
            local U = cat{V, Y}
            S = U
        end
        local J = _kies(K,S)
        return J
    end
    return I
end
local G = _pow(H,10)
local D = G(E)
local A = D(B)
print(string.char(unpack(A)))
