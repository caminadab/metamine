; reflexive: a=b <=> b=a
; distributive: a(b+c) = ab+ac
; associative property: a+(b+c) = (a+b)+c

; logica
true and A => A
false and A => false
true or A => true
false or A => A
A or B = B or A
A and B = B and A
A nor B = B nor A

; basis rekenen
A*B = B*A
A+B = B+A
(A+B)+C = A+(B+C)
(A*B)*C = A*(B*C)
1 * A => A
0 * A => 0
0 + A => A
M*A + A = (M+1)*A
A / 1 => A
A / A => 1
A / 0 => oo
A + A => 2 * A
A * A => A ^ 2
A = B <=> B = A
A < B <=> B > A
A =< B <=> B >= A
;A - B = -A+B
;-(A+B) = -A-B

; machten
sqr[a] = a^2
sqrt[a] = a^(1/2)
cbrt[a] = a^(1/3)
M^E * M = M^(E+1)
M^E / M = M^(E- 1)
M^E * M^F = M^(E+F)
M^1 => M
M^0 => 1
^A = B <=> A = _B
;1^A => 1


; opties
+- a => a | -a
A|B + C => (A+C) | (B+C)
(A|B) * C => (A*C) | (B*C)
A|A => A
A|B = B|A
(A|B)|C = A|(B|C)
(A,B)|C => (A|C),(B|C)
(A|B)^C => (A^C|B^C)
A | B = C => A = C or B = C


; reeksen
;add a..b => (b^2 - a^2) / 2
A..A = 0
A*B = C <=> A = C/B
;A+B = C <=> A = C-B
A = -B <=> -A = B

; lijsten
A,B = C,D => A = C and B = D
A,B + C => (A+C), (B+C)

A = A => true

; vergelijkingen
A = B + C <=> C = A - B
A = B * C <=> C = A / B
A = B ^ C <=> C = A _ B
B = A ^ (1/C) => A = B ^ C

; trigonometrie
sin[tau] => 0
cos[tau] => 1
pi => tau / 2
i^2 = -1
sin[a+tau] = sin[a]

; tekst
(A || B) || C <=> A || (B || C)
A || B = C <=> A = C[0 .. (#C - #B)]
A || B = C <=> B = C[#A .. #C]
