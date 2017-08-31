C = A + B <=> A = C - B

; basis
A + B = B + A
A = B <=> A - B = 0
A + B + C = A + C + B
A = B <=> B = A
A - B = A + -B
A = -B <=> -A = B

C = A * B <=> A = C / B
A / B / C = A / (B * C)
A / B = A * B^-1
A * B = B * A
A * B * C = A * C * B
A * 0 => 0
A * 1 => A
A / 1 => A
0 / A => 0

; pi
pi => acos[-1]

; machten
A^-1 = 1/A
A = B/C <=> A*C/B = 1
A^B = C <=> A = C^(B^-1)
A^B = C <=> B = C _ A
sqrt[A] => A ^ 0.5
A^(B + C) = A^B * A^C
A^(B + 1) = A * A^B
A^(B - C) = A^B / A^C
A^(B * C) = A^B^C
A ^ B = C <=> B = C _ A

; algebra
A*Y^2 + B*Y + C = 0 => Y = (-B +- sqrt[B^2 - 4*A*C]) / (2*a)

; logica
A and B = B and A
A and B and C = A and C and B
A = A => true
A and false => false
A and true => A
A or true => true
A or false => A

; opties
+- A => A | -A
(A|B) * C => (A*C)|(A*B)
(A|B) + C => (A+C)|(A+B)

