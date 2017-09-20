Beschrijving
============

SAS is bedoelt als nieuwe generatie programmeertaal. Het heeft een rijke syntaxis die zoveel mogelijk alledaagse programmeerstijlen en functies probeert aan te bieden, zoals functioneel programmeren, tekstbewerking, contractueel programmeren, en test-gedreven ontwikkeling.

De omgeving SATIS zorgt voor een makkelijk en transparante ontwikkelomgeving, met ingebouwde hulp voor debuggen, profileren, continuele integratie en collaboratief werken.

Door een sterk typesysteem en veilige foutenafhandeling probeert SAS het introduceren van bugs zo moeilijk mogelijk te maken.


Syntax
======

SAS probeert een zo neutraal en simpel mogelijke taal te zijn:
- Alle expressies hebben een waarde
- Is geheel declaratief. Een programma heeft de waarde van zijn uitkomst.


Functies
---------
De volledige syntaxis voor SAS 0.1.0 is:

Standaard rekenkunde:
	a + b		; add a,b
	a - b		; sub a,b
	a * b		; mul a,b
	a / b		; div a,b
	a // b		; idiv a,b
	a ^ b		; pow a,b
	a _ b		; logaritme; log_b(a)
	a % b		; mod a,b

	- b			; neg a
	^ a			; exp a
	_ a			; log a
	( )			; prioriteits haakjes

	oo			; oneindig
	3				; decimaal getal
	10q			; quaternair getal 4
	70o			; octaal getal 56
	FFh			; hexadecimaal getal 255
	3F3Hx		; hexadecimale data ('hu')


Booleaans:
	a > b		; gt a,b
	a < b		; lt a,b
	a >= b	; gte a,b
	a <= b	; lte a,b
	a = b		; eq a,b
	a != b	; neq a,b

Functioneel:
	g @ f		; g@f x = g(f(x))
	a := b	; label a als b

Typesysteem:
	a: b		; a is subset van b
	a: s&t	; a: s and a: t
	a >> t	; a geconverteerd naar type t
	s << a	; a geconverteerd naar type s

Opties:
	t | s		; t danwel s
	a = t|s	; a = t xor a = s
	+- a		; a | -a
	a +- b	; (a + b) | (a - b)
	a = b?	; a = b xor a: undefined


Logica:
	true		; waar
	false		; onwaar
	a and b	; a en b zijn waar
	a or b	; a of b of allebei zijn waar
	a xor b ; a of b is waar
	a nor b	; a noch b is waar
	not a		; a is niet waar
	a => b	; als a waar is dit is b, anders onwaar
	a,b => c	; als a en b waar zijn is c waar
	a <=> b	; als a waar is is b waar en vice versa

Collecties:
	[a,b]		; inline lijst definitie
	a .. b	; reeks a tot b (0..3 = 0,1,2)
	a to b	; bereik
	#l			; lengte van een lijst
	l.i			; indexeer een lijst
	{a,b}		; inline set definitie
	a -> b	; functie/dict/relatie definitie
	num^3		; vector in RR^3
	a in b	; issubset a,b
	a \ b		; verschil tussen a en b
	a - b		; verschil tussen a en b als b in a
	a x b		; cartesisch product

Tekst:
	'hoi\n'		; char lijst
	#t			; tekst lengte
	c || d	; concat c,d

Hierarchie:
	a.b			; b is onderdeel van a
	a,b			; a is gelijkwaardig aan b

Kansrekening:
	a pick b	; ncr a,b


Syntaxis Suiker
---------------
Om SAS mooier te maken.

Het programma:
	1 a = 3
	2 b = a * 2
	3 a
wordt gelezen als `a = 3, b = a * 2  => a`.


Uitvoering
==========

Van broncode naar programma gaat als volgt:
1. parseren
2. oplossen
3. optimisatie
4. compilatie

**Parseren**: lexen, shunting-yard algoritme

Oplossen
--------
1. Isoleren van variabelen en *assert*s
2. Omschrijven naar CNF
3. Oplossingspad vinden
4. Blokken vinden voor trage uitvoering & edge-triggered

Optimisatie
-----------
- **assert** eliminatie
- Gelijke sub-expressies vinden en samenvoegen
- (GPU) Multithreading
- Dode code eliminatie
- Dode data eliminatie
- Constanten vouwen
- Diversen subexp transformaties

### Loops
- Strength Reduction
- Parallelisatie


Error Afhandeling
=================
Alle errors en de waarde *undefined* erven over van *false*.
Een bestand inlezen geeft een waarde van het type *data | file-not-found* wat afleidt van *data?*.
*file-not-found* leidt af van *undefined* en dus ook van *false*.
Op deze manier kan men zeggen

	assemble x = ...
	asm = file 'source.asm'
	asm
		=> assemble asm
		/> 'geen invoer gevonden'

Als de broncode niet wordt gevonden wordt er een bericht teruggegeven en anders wordt de code geassembleerd.

Error-afhandeling is op deze manier beschikbaar zonder speciale constructies in de taal. Errors worden stilletje doorgegeven tot ze niet meer relevant zijn (afgesloten verbinding in een gestopte *thread*) of ongeldige resultaten gaan opleveren (systeem probeert *file-not-found* op het scherm te tekenen). Een voordeel is dat tijdens compile-time ongeldige resultaten al kunnen worden opgespoord met behulp van het type systeem.

Types
=====
In SAS is een type een eigenschap van een waarde. Een waarde kan meerdere types hebben. De constante `3` bijvoorbeeld, is tegelijk *int*, *number*, en *constant*. Het type van een waarde kan tijdens de run-time veranderen: een verbinding kan van *connected* naar *unconnected* gaan. Als er staat

	server-connection : connected
		=> status-icon = icon-green
		/> status-icon = icon-red

wordt er tijdens de runtime geswitcht van een groen naar rood icoon en terug afhankelijk van de verbindingsstatus. Tegelijk kan worden aangenomen dat in het `=>` blok de server-connection altijd `connected` is: handig voor error-eliminatie aangezien `not-connected-error` hier per definitie niet kan voorkomen.


Logica & Opties
===============

Automatische if-statement generatie wordt veroorzaakt door logica en **opties**.
Wanneer je bijv. een opslagsysteem wilt maken die integers en booleans kan opslaan, met integers in de vorm van `!123` en booleans in de vorm van `@false`, bieden opties een uitkomst. Neem het programma

	encoded = encoded-int | encoded-bool
	decoded = int | bool
	encoded-int = '!' || int
	encoded-bool = '@' || bool
	decoded

Wanneer je vervolgens `encoded = '!3'` zegt probeert het programma uit of encoded een encoded-int kan zijn; als dit slaagt is decoded de int achter het uitroepteken, en anders de booleaanse waarde achter het apenstaartje.
Wanneer je echter iets onmogelijks zegt zoals `encoded = '#pi'` kan de eerste regel niet waar worden gemaakt, waardoor de laatste regel ook onwaar is; immers alle regels in het programma moeten waar zijn voordat de laatste regel een waarde aanneemt.

Dit "uitproberen" wordt een keer gedaan door de oplosser en compiler; hierna wordt het getransformeerd naar programmacode net als de rest van de broncode. Vgl Prolog waar dit niet het geval is; hier wordt het trage *backtracking* gebruikt. 


Bibliotheek
===========

SAS 0.1.0 biedt een standaard bibliotheek met de volgende naamruimte:

`fs`				lokaal filesystem
`ip.tcp` 		netwerken
`math`			wiskundige functies
`math.trig`	trigonometrie
`asm`				assembleer onszelf
`axiom`			feiten over onszelf
`opt`				optimisatie methoden

