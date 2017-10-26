Open Vraagstukken
=================
*24-11-2017*

1. Wat betekent een regeleinde?
2. Matrices?
3. Sets/Lijsten met komma's of spaties?
4. Functie aanroep?
5. [sin pi] = [sin,pi] of [sin(pi)] ?
6. Conditie functie; mag dit?

	f: number -> number
	f = {
	  0..3 -> 1/3
	  else -> 0
	}

7. Betekent `:` dan "subset van" of "lid van" of allebei?

8. Welke van de volgende:

- if a then p = 100 else p = 0
- p = (a -> 100, else -> 0)
- p = a -> 100 & else -> 0
- p = if a then 100 else 0
- p = if a, 100, else 0
- p = a => 100, a /> 100
- p = a => 100 & else => 100
- p = a ? 100 else 0

9. Welke van deze:
- p =
		(b=0)	-> 0
		(b=1)	-> 100
		else	-> '?'

- p =
		if b=0 then 0
		elseif b=1 then 100
		else '?'

- p =
		if b=0
			0
		elseif b=1
			1
		else
			'?'


10. Is regeleind gelijk aan 'then' bij 'if'?
11. Wat is de waarde van `false,1=>true` ?
12. En van `1 & 2 & false` ?
13. wat is de waarde van `2 -> 3`?
14. Type conversie: `3 >> text` of `3: text` of `3 as text`?
15. Is `int x int` gelijk aan `int,int`? En `int^2`?
16. Lijst: int^int, int.i, int[]?
Als [1] || [2] gelijk aan [1 2] is,
18. Is 1 || [2] gelijk aan [1 [2]] of [1 2] of undefined?
19. Is 1,[2] gelijk aan [1 [2]] of [1 2]?
20. Hoe te zeggen: concateneer 1 aan [2 3] ?
21. Is `{1,2} gelijk aan {1 2}?
22. Is `[1,(2,3)]` gelijk aan [`(1,2),3]`?
23. Is `(1,2) * (2,3)` gelijk aan `(1,6)` of `((1,2),(1,3),...)`?
24. Functie overloading?
25. Is {a} * {b,c} = {(a,b), (b,c)} ? Hopelijk ja
26. Is [a,b] * [c,d] = [a*c,b*d] ?
27. Wat is {a} * [b,c] ?
28. Mag (a,b) als tuple of is dat [a,b]? is het ook a,b ?
29. is {1} : {1,2}? Is 1:{1,2}? Is 1 in {1,2}? is {1} in {1,2}?
30. Waarde van "0<a" in "0<a<1" ?

Lua
===

[a b +] =
{
	{'a', 'b', '+'}, -- symbols
	{false, false, true}, -- is function of value
}
OF
{
	{text='a', fn=false}
}


Lex
===

ops = name -> op x arity
lex: sas -> tokens
mixfix: sas -> prefix
mixfix 'a + b' = [a b +]
mixfix '- a' = [a -]
mixfix 'a / b ^ c' = [a b c ^ /]
mixfix '(sin @ sin)(1)' = [.1 .sin .sin @]
mixfix 'sin 1' = [1 sin]

sin2 = sin @ sin
sin2(1)

y atan x = atan2(x,y)

_ 10 = log 10
^ 10 = exp 10


Symbolisch
==========

subst: rpn -> rpn
