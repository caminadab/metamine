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
local D = tabel{104,111,105}
local E = tabel{104,111,101}
local F = tabel{105,115}
local G = tabel{104,101,116}
local H = tabel{114,117,98,101,110}
local C = tabel{D,E,F,G,H}
local J = function (_C)
    local L = tabel{}
    local M = function (_D)
        local P = #(_D)
        local O = tabel{P}
        local N = cat{O, _D}
        return N
    end
    for i=1,#_C do
        L[i] = M(_C[i])
    end
    local K = cat(L)
    return K
end
local Q = function (_B)
    local U = tabel{}
    local T = tabel{_B,U}
    local W = function (_A)
        local CB = _A(0)
        local BB = #(CB)
        local AB = BB ~= 0
        local Z = false
        if AB then
            local EB = _A(0)
            local IB = _A(0)
            local HB = IB(0)
            local GB = 1 + HB
            local FB = tabel{1,GB}
            local DB = deel(EB,FB)
            Z = DB
        end
        local Y = false
        if Z then
            local KB = _A(0)
            local NB = _A(0)
            local MB = NB(0)
            local LB = 1 + MB
            local JB = vanaf(KB,LB)
            Y = JB
        end
        local TB = _A(0)
        local SB = #(TB)
        local RB = SB ~= 0
        local QB = false
        if RB then
            local VB = _A(0)
            local ZB = _A(0)
            local YB = ZB(0)
            local XB = 1 + YB
            local WB = tabel{1,XB}
            local UB = deel(VB,WB)
            QB = UB
        end
        local PB = false
        if QB then
            local BC = _A(1)
            local GC = _A(0)
            local FC = #(GC)
            local EC = FC ~= 0
            local DC = false
            if EC then
                local IC = _A(0)
                local MC = _A(0)
                local LC = MC(0)
                local KC = 1 + LC
                local JC = tabel{1,KC}
                local HC = deel(IC,JC)
                DC = HC
            end
            local CC = tabel{DC}
            local AC = cat{BC, CC}
            PB = AC
        end
        local SC = _A(0)
        local RC = #(SC)
        local QC = RC ~= 0
        local PC = false
        if QC then
            local UC = _A(0)
            local YC = _A(0)
            local XC = YC(0)
            local WC = 1 + XC
            local VC = tabel{1,WC}
            local TC = deel(UC,VC)
            PC = TC
        end
        local OC = not(PC)
        local NC = false
        if OC then
            local ZC = _A(1)
            NC = ZC
        end
        local OB = _kies(PB,NC)
        local X = tabel{Y,OB}
        return X
    end
    local V = _pow(W,9)
    local S = V(T)
    local R = S(1)
    return R
end
local I = _comp(J,Q)
local B = I(C)
local AD = tabel{44,32}
local A = cat(B,AD)
print(string.char(table.unpack(A)))
