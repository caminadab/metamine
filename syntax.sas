;;
; infix
alpha-num-a = alpha + numeric
a = b + c ^ d * e / f
f = g @ h^2
a = -#b.c
_a = b
a = b_c
y = +- x * 2
a b
a = b c
a b c = d
a b (c d) = (e f) g (h i)

a = [1,2,3]
[
	'hoi'
	'hee'
	'ha'
]

[
	1,2,3
	4,5,6
	7,8,9
]

[[1]]
[[1,2],[3,4]]

[
	[1,2]
	[3,4]
]

g = [
	'1'
	'2.1', '2.2'
	['3']
]

; dictionary
h = {
	0..9		-> 'a'
	10..100	-> 'b'
}

; hmm
a = [
;	0, -1, .3e-2, 982d
;	0h, 0A2384.FFh, 10.01101b
;	028x, DEADBEEFx, 0123456789ABCDEFx
;	132202q, 3.33q
]

a as text = '3'
a = 3

; if statements
if b is boolean
	a = 'ja'
elseif b is int and b in 0..3
	a = 'half'
else
	a = 'nee'

; inline if (niet ondersteund)
;a = if not b then 3 else 2

; rule if
if
	villagers > 10
	attack-risk < 0.8
	advantage >= high
then
	army-production = high
	attack-enabled

; functies
f: number -> number
f = {
	0..3 -> 1/3
	else -> 0
}

dir = {left, mid, right}
sign = {-1, 0, 1}
f: dir -> sign
f = {
	left	-> -1
	mid		-> 0
	right -> 1
}

f(x) = 1  =>  x = right

angle = 0..tau
complex = number + number * math.i

tau/4 : angle

atan: number -> angle
atan: complex != 0 -> angle

atan = {
	[x>0,y]	-> sgn y * atan abs(y/x)
	[x=0,y!=0] -> sgn y * (tau/4)
	[x<0,y]	-> sgn x * (pi - atan abs(y/x))
}
;;

cannon.angle = atan cannon.target.pos | 0

complex isomorph number^2
complex >> number^2 =
	complex = a + b * math.i
	[a,b]

number^2 >> complex =
	ab = number^2
	ab.1 + ab.2 * math.i

; blockfix
total-rescues =
	+ high-rescues
	+ medium-rescues
	+ low-rescues

sqrt
	+ target-xpos - user-xpos
	+ target-ypos - user-ypos

; userfix
a = sin b
a = b atan c
a = (cos b) atan c
a = sin (b atan c)

;d = a b c d e ERROR: ambigue gebruikersoperatoren
a = text find sub							; sub0 text0 find2
b = reverse text find sub			; text0 reverse1 sub0 find2
c = inverse unm compose sin		; unm0 inverse1 sin0 compose2
reverse text = text.(#..0)

unm: number -> number
