
; algebra
; op[a,b] and op: reflexive => op[a,b] = op[b,a]
; reflexive: a=b <=> b=a
; distributive: a(b+c) = ab+ac
; associative property: a+(b+c) = (a+b)+c

true and A => A
false and A => false
true or A => true
false or A => A

a*b => b*a
a+b => b+a
1*a => a
0*a => 0
0+a => a
a/1 => a
a/0 => oo
;abs[-a] >= a
a+a => 2*a
a*a => a^2
;a-b = -a+b
;-(a+b) = -a-b

; machten
;sqr[a] = a^2
;sqrt[a] = a^(1/2)
;cbrt[a] = a^(1/3)
i^2 = 1
a^b = c <=> a = b^(1/c)
1/a^b = a^(1/b)
m^e * m = m^(e+1)
m^e * m^f = m^(e+f)

; opties
;+- a => a | -a
a|b + c => (a+c) | (b+c)
;associative[opt]
a|a => a

; reeksen
;add a..b => (b^2 - a^2) / 2
a..a = 0
a*b = c <=> a = c/b
a+b = c <=> a = c-b

;associative[=?]
a=a => true
a=?a => true

; trigonometrie
;sin[tau] => 0
;cos[tau] => 1
pi = tau / 2
;sin[a+tau] = sin[a]
; typen
;	(=>
;		(and
;			(: V FROM)
;			(= (>> FROM TO) CONV)
;			(>> V CONV)
;		)
;	)
