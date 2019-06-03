tau = Math.PI * 2;
start = new Date().getTime() / 1000;

function str2arr(s) {
    var t = [];
    for (var i = 0; i < s.length; i++)
        t.push(s.charCodeAt(i));
    return t;
}

function arr2str(a) {
    var s = "";
    for (var i = 0; i < a.length; i++)
        s += String.fromCodePoint(a[i]);
    return s;
}

var ja = true;

var nee = false;

/*
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
*/
var _comp = function(a,b) {
    return function() {
        return b(a(arguments))
    };
};

function _I(a,i,...args) {
    if (Array.isArray(a))
        return a[i];
    else {
        //var args = [];
        //for (var i = 1; i < arguments.length; i++)
            //args.push( arguments[i] );
        //return a.apply(a, args);
        return a(i,...args);
    }
}

function vanaf(a,van) {
    return a.splice(van,a.length);
}

function tot(a,tot) {
    return a.splice(0,tot);
}

function deel(a,b) {
    return a.splice(b[0],b[1]);
}
/*
function tabel(t)
    var t = t || {}
    local mt = {}
    function mt:__call(i)
        return t[i+1]
    end
    setmetatable(t, mt)
    return t
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
*/

function cat(a, b) {
    var r = [];
    for (var i = 0; i < a.length; i++) {
        r = r.concat(a[i]);
        if (b && i != a.length - 1) r = r.concat(b);
    }
    return r;
}

function tekst(a) {
    var str;
    if (Array.isArray(a))
        str = arr2str(a);
    else
        str = "" + a;
    return str2arr(str);
}

var _procent = function(a) { return a / 100; }

var sin = Math.sin;
var cos = Math.cos;
var tan = Math.tan;
var int = Math.floor;
var abs = Math.abs;

function _iinterval(a, b) {
    var t = [];
    for (var i = a; i < b; i++) {
        t.push(i);
    }
    return t;
}

function som(l) {
    var s = 0;
    for (var i = 0; i < l.length; i++) {
        s += l[i];
    }
    return s;
}

function _kies(a,b) {
    return a || b;
}

function rechthoek(abc) { return [1, abc[0], abc[1], abc[2] ]; }
function schrijf(abc) { return [2, abc[0], abc[1], abc[2] ]; }

function atoom(i) {
    return "##" + i;
}

var groen = [0,1,0];
var rood = [1,0,0];
var wit = [1,1,1];
var zwart = [0,0,0];

tau = Math.PI * 2;
start = new Date().getTime() / 1000;

function str2arr(s) {
    var t = [];
    for (var i = 0; i < s.length; i++)
        t.push(s.charCodeAt(i));
    return t;
}

function arr2str(a) {
    var s = "";
    for (var i = 0; i < a.length; i++)
        s += String.fromCodePoint(a[i]);
    return s;
}

var ja = true;

var nee = false;

/*
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
*/
var _comp = function(a,b) {
    return function() {
        return b(a(arguments))
    };
};

function _I(a,i,...args) {
    if (Array.isArray(a))
        return a[i];
    else {
        //var args = [];
        //for (var i = 1; i < arguments.length; i++)
            //args.push( arguments[i] );
        //return a.apply(a, args);
        return a(i,...args);
    }
}

function vanaf(a,van) {
    return a.splice(van,a.length);
}

function tot(a,tot) {
    return a.splice(0,tot);
}

function deel(a,b) {
    return a.splice(b[0],b[1]);
}
/*
function tabel(t)
    var t = t || {}
    local mt = {}
    function mt:__call(i)
        return t[i+1]
    end
    setmetatable(t, mt)
    return t
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
*/

function cat(a, b) {
    var r = [];
    for (var i = 0; i < a.length; i++) {
        r = r.concat(a[i]);
        if (b && i != a.length - 1) r = r.concat(b);
    }
    return r;
}

function tekst(a) {
    var str;
    if (Array.isArray(a))
        str = arr2str(a);
    else
        str = "" + a;
    return str2arr(str);
}

var _procent = function(a) { return a / 100; }

var sin = Math.sin;
var cos = Math.cos;
var tan = Math.tan;
var int = Math.floor;
var abs = Math.abs;

function _iinterval(a, b) {
    var t = [];
    for (var i = a; i < b; i++) {
        t.push(i);
    }
    return t;
}

function som(l) {
    var s = 0;
    for (var i = 0; i < l.length; i++) {
        s += l[i];
    }
    return s;
}

function _kies(a,b) {
    return a || b;
}

function rechthoek(abc) { return [1, abc[0], abc[1], abc[2] ]; }
function schrijf(abc) { return [2, abc[0], abc[1], abc[2] ]; }

function atoom(i) {
    return "##" + i;
}

var groen = [0,1,0];
var rood = [1,0,0];
var wit = [1,1,1];
var zwart = [0,0,0];

nu = new Date().getTime() / 1000;
looptijd = nu - start;
    var A = _I(xcb_connect, 0,0);

    A = A;
if (Array.isArray(A))A = arr2str(A);