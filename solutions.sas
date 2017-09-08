o1 + i1 = i2	=>	o1 = i2 - i1
i1 + o1 = i2	=>	o1 = i2 - i1
o1 - i1 = i2	=>	o1 = i2 + i1
i1 - o1 = i2	=>	o1 = i1 - i2
i1 = -o1			=>	o1 = -i1

o1 * i1 = i2	=>	o1 = i2 / i1
i1 * o1 = i2	=>	o1 = i2 / i1
o1 / i1 = i2	=>	o1 = i2 * i1
i1 / o1 = i2	=>	o1 = i1 / i2
i1 / o1 = i2	=>	o1 = i1 / i2

o1 ^ i1 = i2	=>	o1 = i2 ^ (1/i1)
i1 ^ o1 = i2	=>	o1 = i2 _ i1

sin o1 = i1		=>	o1 = asin i1
cos o1 = i1		=>	o1 = acos i1

; tekst
; #o1 + #i1 = #i2
;i1 || o1 || i2 = o2	=> o1 = o2.[#i1..#i2 - #i1]
o1 || i1 = i2	=>	o1 = i2.[0..(#i2-#i1)] and i1 = i2.[#i2-#i1 .. #i2]
i1 || o1 = i2	=>	o1 = i2.[#i1..#i2] and i1 = i2.[0..#i1]
o1 || i1 || o2 = i2	=>	o1 = i2.[0..find(i2,i1)] and o2 = i2.[find(i2,i1) + #i1 .. #i2]
o1 || o2 = i1	=>	#o1 + #o2 = #i1
i1 != i2 || o1 || i3	=> i2 != i1.[0..#i1] or i3 != i1.[#i1 - #i3 .. #i3]

; lijsten
;o1.i1 = i2		=>	o1 = i2

; opties
;o1 = o2 | o3	=> o1 = o2 or o1 = o3
;o1 = i1 or o2 = i2	=> 
;o1 = o2 | o3	=> [((o1 = o2) => (o1 != o3)) and ((o1 = o3) => (o1 != o2)) and ((o1 != o3) => (o1 = o2)) and ((o1 != o2) => (o1 = o3))]
o1 = i2 | i3	=> i1 = o2 xor i1 = o3 
;o1 = o2 | o3 	=> o1 = o2 and o1 = o3
;o1 xor (o1 and i1)	=>
;o1 = o2 | o3 => (o1 = o2 => o2) & (o1 = o3 => o3)

; logica
(o1 xor o2) and (o3 xor o4)	=>	(o1 and o3) xor (o1 and o4) xor (o2 and o3) xor (o2 and o4)

true

