; types
val = int | data | dict | list
dict = text -> val
list = val^int

benc = val >> bval
bdec = inv benc
benc int = 'i' || int || 'e'
benc data = #data || ':' || data
benc list = 'l' || benc list() || 'e'
benc dict = 'd' || bdict dict || 'e'
bdict dict =
	dict k ; k = B,A
	K = sort[k] map benc; [A,B]
	V = dict(K) map benc; [0,1]
	e = K zip V; [[A,0],[B,1]]
	f = e map ||; [A0,B1]
	|| f ; A0B1
;
K = ['naam', 'tijd']
dict(K) = ['hoi', 3]

; aannames
[0,1]: int^int
0,1: int,int

0..3 = 0,1,2
a 0..3 = a 0, a 1, a 2

[a,b,c] i = a,b,c
i = 0,1,2

0,1,2 + 1,1,1 = 1,2,3

; demo
a = {
	naam -> 'hoi'
	tijd -> 3
}

uit = benc a
