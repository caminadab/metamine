; basis
a = b + c ^ d * e / f
f = g @ h^2
a = -#b.c
_a = b
a = b_c
y = +- x * 2
sgn -3 = 1

b: boolean
b != 3
a = if not b then 3 else 2 end
a =
	if not b
		3
	else
		2

; functies
f: number -> number
f = {
	0..3 -> 1/3
	else -> 0
}
a = {
	b			-> 100
	else	-> 0
}

dir = {left, mid, right}
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
	(x>0,y)	-> sgn y * atan(abs(y/x))
	(x=0,y!=0) -> sgn y * (tau/4)
	(x<0,y)	-> sgn x * (pi - atan(abs(y/x)))
}

cannon.angle = atan cannon.target.pos | 0

complex isomorph number^2
complex >> number^2 =
	complex = a + b * math.i
	[a,b]

number^2 >> complex =
	ab = number^2
	ab.1 + ab.2 * math.i

total-rescues =
	+ high-rescues
	+ medium-rescues
	+ low-rescues


a = unm
b = sub
d = a b c d e
; - b * - e
; a + c - e

; a = { 'hoi' }
; b = add 'hee'
; c = remove 'hoi'
; d = a + b + c
; e = { 'hee' }
a = text find sub							; sub0 text0 find2
b = reverse text find sub			; text0 reverse1 sub0 find2
c = inverse unm compose sin		; unm0 inverse1 sin0 compose2
reverse text = text.(#..0)

unm: number -> number
