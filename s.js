MAKKELIJK	/\	->(iets bit)
MAKKELIJK	tekening	,(pos vorm kleur)
MAKKELIJK	tekst	->(iets tekst)
MAKKELIJK	[]	->(iets ^(iets int))
MAKKELIJK	[]	->(iets ^(iets int))
MAKKELIJK	0	int
MAKKELIJK	0	int
MAKKELIJK	1	kommagetal
MAKKELIJK	1	kommagetal
MAKKELIJK	cirkel	straal
MAKKELIJK	straal	getal
MAKKELIJK	groen	kleur
MAKKELIJK	50	kommagetal
MAKKELIJK	50	kommagetal
MAKKELIJK	straal	getal
MAKKELIJK	3	kommagetal
MAKKELIJK	0	int
MAKKELIJK	0	int
MAKKELIJK	0	int
MAKKELIJK	groen	kleur
MAKKELIJK	0	int
MAKKELIJK	/	->(,(getal getal) getal)
MAKKELIJK	4	kommagetal
MAKKELIJK	5	kommagetal
MAKKELIJK	0	int
MAKKELIJK	cirkel	straal
MAKKELIJK	1	kommagetal
MAKKELIJK	2	kommagetal
  RET	^(iets int)
  RET	tekst
s.code@1:12-41: "tekst ([achtergrond, speler])" is "pos,vorm,kleur" maar moet zijn "tekst"
Typegraaf:
() -> iets
,(pos vorm kleur) -> tekening
->(,(->(int iets) ->(iets bit)) ->(int iets)) -> waarvoor
->(,(^(iets int) ^(iets int)) ^(iets int)) -> ||
->(,(^(iets int) ^(iets int)) int) -> deel
->(,(^(iets int) ^(iets int)) int) -> vind
->(,(^(iets int) int) ^(iets int)) -> tot
->(,(^(iets int) int) ^(iets int)) -> vanaf
->(,(getal getal) bit) -> <
->(,(getal getal) bit) -> =>
->(,(getal getal) bit) -> >
->(,(getal getal) bit) -> >=
->(,(getal getal) getal) -> *
->(,(getal getal) getal) -> +
->(,(getal getal) getal) -> -
->(,(getal getal) getal) -> /
->(,(getal getal) getal) -> ^
->(,(getal getal) getal) -> mod
->(,(int int) ^(int int)) -> ..
->(->(iets iets) ->(iets iets)) -> herhaal
->(->(int getal) getal) -> som
->(^(iets int) int) -> #
->(iets ^(iets int)) -> []
->(iets bit) -> /\
->(iets bit) -> cijfer
->(iets iets) -> ->(iets getal)
->(iets int) -> ^(iets int)
->(iets tekst) -> tekst
->(int byte) -> data
->(int int) -> ->(int teken)
->(int int) -> ^(int int)
^(genormaliseerd 3) -> kleur
bit -> ja
bit -> nee
getal -> genormaliseerd
getal -> int
getal -> kommagetal
getal -> straal
getal -> tijdstip
iets -> ,(pos vorm kleur)
iets -> ->(,(getal getal) getal)
iets -> ->(iets ^(iets int))
iets -> ->(iets bit)
iets -> ->(iets iets)
iets -> ->(iets int)
iets -> ->(iets tekst)
iets -> ^(iets int)
iets -> getal
iets -> int
iets -> kleur
iets -> kommagetal
iets -> straal
iets -> tekst
int -> teken
kleur -> blauw
kleur -> geel
kleur -> groen
kleur -> paars
kleur -> rood
straal -> cirkel
tekst -> uit
tijdstip -> nu
vorm -> cirkel
  RET	^(iets int)
  ARG	4	getal	13:12-13
  ARG	5	getal	13:14-15
  RET	getal
  RET	bit
  RET	^(iets int)
  RET	tekst
  RET	^(iets int)
  ARG	4	getal	13:12-13
  ARG	5	getal	13:14-15
  RET	getal
  RET	bit
  RET	^(iets int)
  RET	tekst
  RET	^(iets int)
  ARG	4	getal	13:12-13
  ARG	5	getal	13:14-15
  RET	getal
  RET	bit
  RET	^(iets int)
  RET	tekst
  RET	^(iets int)
  ARG	4	getal	13:12-13
  ARG	5	getal	13:14-15
  RET	getal
  RET	bit
TYPERING GESLAAGD - PROGRAMMA IS ZINVOL
Web
