local tau = math.pi * 2
local ja = true
local nee = false
local pack = pack or table.pack
local unpack = unpack or table.unpack
local max = math.max
local min = math.min
local abs = math.abs
local sin = math.sin
local cos = math.cos
local tan = math.tan
local function cijfer(a)
    return string.byte('0', 1) <= a and a <= string.byte('9', 1)
end
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
    for i = 1,b-1 do
        t[#t+1] = i
    end
    return t
end;
local waarvoor = function(l,fn)
    local r = {}
    for i,v in ipairs(l) do
        if fn(v) then
            r[#r+1] = v
        end
    end
    return r
end

local som = function(t)
    local som = 0
    for i,v in ipairs(t) do
        som = som + v
    end
    return som
end;
local _istype = function(a,b)
    if type(b) == 'table' and b.is and b.is.set then
        return b.set[a]
    end
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
    local t = t or {is={lijst=true}}
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

cache = cache or {}
local function bestand(naam)
    local naam = string.char(table.unpack(naam))
    if cache[naam] then return cache[naam] end
    local f = io.open(naam)
    local data = f:read('*a')
    f:close()
    local data,err = table.pack(string.byte(data, 1, #data))
    setmetatable(data, getmetatable(tabel()))
    local t = tabel{}
    for i=1,#data do
        t[i] = data[i]
    end
    cache[naam] = t
    return t
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

local socket = require 'socket'
start = start or socket.gettime()
nu = socket.gettime()

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

local function tekstR(a,t)
    if type(a) == 'table' then
        if a.is and a.is.tupel then t[#t+1] = '('
        elseif a.is and a.is.lijst then t[#t+1] = '['
        elseif a.is and a.is.set then t[#t+1] = '{'
        end

        if a.is and a.is.set then
            for k in pairs(a.set) do
                tekstR(k,t)
                if next(a.set,k) then
                    t[#t+1] = ','
                end
            end
        else
            for i,v in ipairs(a) do
                tekstR(v,t)
                if i < #a then
                    t[#t+1] = ','
                end
            end
        end

        if a.is and a.is.tupel then t[#t+1] = ')'
        elseif a.is and a.is.lijst then t[#t+1] = ']'
        elseif a.is and a.is.set then t[#t+1] = '}'
        end
    else
        t[#t+1] = tostring(a)
    end
            
end

local function tekst(a)
    local t = {}
    tekstR(a, t)
    local t = table.concat(t)
    return {string.byte(t,1,#t)}
end

local xx = function(a,b)
    if type(a) == 'table' and a.is and a.is.set then
        if type(b) == 'table' and b.is and b.is.set then
            local res = {is={set=true},set={}}
            for sa in pairs(a.set) do
                for sb in pairs(b.set) do
                    res.set[{is={tupel=true}, sa, sb}] = true
                end
            end
            return res
        end
    end
            
    if type(a) == 'table' and a.is and a.is.tupel then
        if type(b) == 'table' and b.is and b.is.tupel then
            for i=1,#b do
                a[#a+1] = b[i]
            end
        else
            a[#a+1] = b
        end
    else
        if type(b) == 'table' and b.is and b.is.tuple then
            table.insert(b, 1, a)
            a = b
        else
            a = {is={tupel=true}, a, b}
        end
    end
    return a
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

local function _len(t)
    if type(t) == 'table' and t.is and t.is.set then
        local len = 0
        for _ in pairs(t.set) do len = len + 1 end
        return len
    end
    if type(t) == 'table' and t.is and (t.is.tupel or t.is.lijst) then
        return #t
    end
end
local E = tabel{108,108}
local F = tabel{}
local D = tabel{E,F}
local H = function (_A)
    local N = _A(0)
    local M = N(0)
    local L = cijfer(M)
    local K = false
    if L then
        local P = _A(0)
        local S = _A(0)
        local R = vind(S,58)
        local Q = R + 1
        local O = vanaf(P,Q)
        K = O
    end
    local W = _A(0)
    local V = W(0)
    local U = V == 100
    local T = false
    if U then
        local Y = _A(0)
        local X = vanaf(Y,1)
        T = X
    end
    local AC = _A(0)
    local AB = AC(0)
    local AA = AB == 108
    local Z = false
    if AA then
        local AE = _A(0)
        local AD = vanaf(AE,1)
        Z = AD
    end
    local AI = _A(0)
    local AH = AI(0)
    local AG = AH == 105
    local AF = false
    if AG then
        local AK = _A(0)
        local AN = _A(0)
        local AM = vind(AN,101)
        local AL = AM + 1
        local AJ = vanaf(AK,AL)
        AF = AJ
    end
    local J = _kies(K,T,Z,AF)
    local AS = _A(0)
    local AR = AS(0)
    local AQ = AR == 100
    local AP = false
    if AQ then
        local AU = _A(1)
        local AV = tabel{4}
        local AT = cat{AU, AV}
        AP = AT
    end
    local AZ = _A(0)
    local AY = AZ(0)
    local AX = cijfer(AY)
    local AW = false
    if AX then
        local BB = _A(1)
        local BC = tabel{1}
        local BA = cat{BB, BC}
        AW = BA
    end
    local BG = _A(0)
    local BF = BG(0)
    local BE = BF == 108
    local BD = false
    if BE then
        local BI = _A(1)
        local BJ = tabel{3}
        local BH = cat{BI, BJ}
        BD = BH
    end
    local BN = _A(0)
    local BM = BN(0)
    local BL = BM == 105
    local BK = false
    if BL then
        local BP = _A(1)
        local BQ = tabel{2}
        local BO = cat{BP, BQ}
        BK = BO
    end
    local AO = _kies(AP,AW,BD,BK)
    local I = tabel{J,AO}
    return I
end
local G = _pow(H,2)
local C = G(D)
local B = C(1)
local A = tekst(B)
return A
