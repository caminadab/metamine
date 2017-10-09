bron: lijn^int
asb: inhoud^boom

lijn = tabs || inhoud || comment? || '\n'
comment = ';' || tekst

; di = diepte-index: (int^int)^int ; depth-first
; di.diepte = #di

fact n
	n = 1 => 0
	n > 1 => n * fact n-1

sign n
	(n > 0) -> 1
	(n = 0) -> 0
	(n < 0) -> -1

sign 3 = 1 & false & false = 1



n > 0 => sign n = 1
if n > 0
	1
if n = 0
	0
if n < 0
	-1

(true => 1 | false => 0)

(= (fact n)
	(= n 1)

asb >> bron
	asb.di: (di & inhoud)
	bron = concat lijn
		# tabs = # asb.di
		inhoud = asb.di.inhoud

; text >> int

A				; 0
	B			; 0 0
C				; 1
	D			; 1 0
	E			; 1 1
		F		; 1 1 1
	G			; 1 2
	H			; 1 3
I				; 2
	J			; 2 0
		K		; 2 0 0
L				; 3

