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

local D = tabel{98,100,101,99,40,39}
local E = tabel{108,108,101,105,51,101,105,52,101,101}
local C = cat{D, E}
local F = tabel{39,41,32,61,32}
local B = cat{C, F}
local H = tabel{108,108,101,105,51,101,105,52,101,101}
local J = function (_A)
    local K = tabel{}
    return K
end
local M = function (_B)
    local N = function (_D)
        local S = #(_D)
        local R = S > 0
        local Q = false
        if R then
            local U = _D(0)
            local T = U == 105
            Q = T
        end
        local P = false
        if Q then
            local Y = tabel{101}
            local X = vind(_D,Y)
            local W = 1 + X
            local V = tot(_D,W)
            P = V
        end
        local CB = #(_D)
        local BB = CB > 0
        local AB = false
        if BB then
            local EB = _D(0)
            local DB = EB == 108
            AB = DB
        end
        local Z = false
        if AB then
            local HB = tabel{108}
            local MB = vanaf(_D,1)
            local NB = tabel{}
            local LB = tabel{MB,NB}
            local PB = function (_C)
                local SB = _C(0)
                local RB = _B(SB)
                local QB = false
                if RB then
                    local VB = _C(0)
                    local YB = _C(0)
                    local XB = _B(YB)
                    local WB = #(XB)
                    local UB = vanaf(VB,WB)
                    local AC = _C(1)
                    local DC = _C(0)
                    local CC = _B(DC)
                    local BC = tabel{CC}
                    local ZB = cat{AC, BC}
                    local TB = tabel{UB,ZB}
                    QB = TB
                end
                return QB
            end
            local OB = _pow(PB,9)
            local KB = OB(LB)
            local JB = KB(1)
            local IB = cat(JB)
            local GB = cat{HB, IB}
            local EC = tabel{101}
            local FB = cat{GB, EC}
            Z = FB
        end
        local O = _kies(P,Z)
        return O
    end
    return N
end
local L = _pow(M,9)
local I = L(J)
local G = I(H)
local A = cat{B, G}
print(string.char(unpack(A)))
