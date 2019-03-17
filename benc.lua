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

local C = tabel{2}
local D = tabel{}
local G = tabel{}
local F = tabel{G}
local E = tabel{F,4}
local B = tabel{1,C,3,D,E}
local I = function (_A)
    local L = _istype(_A,int)
    local K = false
    if L then
        local O = tabel{105}
        local P = tekst(_A)
        local N = cat{O, P}
        local Q = tabel{101}
        local M = cat{N, Q}
        K = M
    end
    local S = _istype(_A,lijst)
    local R = false
    if S then
        local V = tabel{108}
        local X = tabel{}
        for i=1,#_A do
            X[i] = _B(_A[i])
        end
        local W = cat(X)
        local U = cat{V, W}
        local Y = tabel{101}
        local T = cat{U, Y}
        R = T
    end
    local J = _kies(K,R)
    return J
end
local Z = function (_B)
    local AB = function (_A)
        local DB = _istype(_A,int)
        local CB = false
        if DB then
            local GB = tabel{105}
            local HB = tekst(_A)
            local FB = cat{GB, HB}
            local IB = tabel{101}
            local EB = cat{FB, IB}
            CB = EB
        end
        local KB = _istype(_A,lijst)
        local JB = false
        if KB then
            local NB = tabel{108}
            local PB = tabel{}
            for i=1,#_A do
                PB[i] = _B(_A[i])
            end
            local OB = cat(PB)
            local MB = cat{NB, OB}
            local QB = tabel{101}
            local LB = cat{MB, QB}
            JB = LB
        end
        local BB = _kies(CB,JB)
        return BB
    end
    return AB
end
local H = Z(I)
local A = H(B)
print(string.char(unpack(A)))
