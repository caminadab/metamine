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

local C = tabel{}
local D = function (_A)
    local E = _A(0)
    return E
end
local F = function (_C)
    local J = _procent(100)
    local K = _procent(50)
    local L = _procent(0)
    local I = tabel{J,K,L}
    local H = tabel{0,100,100,10,I}
    local G = tabel{H}
    return G
end
local B = tabel{C,D,F}
local M = function (_B)
    local P = tabel{10,60,104,116,109,108,62,10,60,99,97,110,118,97,115,32,119,105,100,116,104,61,39,52,50,56,39,32,104,101,105,103,104,116,61,39,50,52,48,39,62,10,60,47,99,97,110,118,97,115,62,10,60,115,99,114,105,112,116,62,10,9,118,97,114,32,116,101,107,101,110,32,61,32,102,117,110,99,116,105,111,110,40,41,32,123,10,9}
    local R = function (_C)
        local V = _procent(100)
        local W = _procent(50)
        local X = _procent(0)
        local U = tabel{V,W,X}
        local T = tabel{0,100,100,10,U}
        local S = tabel{T}
        return S
    end
    local Q = javascript(R)
    local O = cat{P, Q}
    local Y = tabel{10,9,125,59,10,10,9,47,47,118,97,114,32,99,10,9,47,47,118,97,114,32,98,32,61,32,32,10,9,47,47,118,97,114,32,116,101,107,101,110,10,9,47,47,100,100,46,99,108,101,97,114,82,101,99,116,40,48,44,32,48,44,32,99,97,110,118,97,115,46,119,105,100,116,104,44,32,99,97,110,118,97,115,46,104,101,105,103,104,116,41,59,10,60,47,115,99,114,105,112,116,62,10,60,47,104,116,109,108,62,10}
    local N = cat{O, Y}
    return N
end
local A = M(B)
print(string.char(unpack(A)))
