# Types
Types in taal zijn sets die *at compile time* gedefinieerd moeten zijn. Een object
kan meerdere types hebben; dit kan ook *at runtime* veranderen.

# Ontologie
Alle objecten in taal zijn van type "iets" of "niets".
Geldige waarden zijn altijd van type "iets" terwijl fouten van type "niets" zijn.
Een bestand lezen dat niet bestaat levert bijvoorbeeld "bestand niet gevonden" op,
van het subtype "fout", welke weer subtype "niets" heeft.

# Objecten
Met "groen." definieer je een nieuw object "groen". Met "secondes(int)." maak je
het mogelijk nieuwe objecten met int als argument te definiëren, bijvoorbeeld

    f = seconden(3)

# Getallen
Taal onderscheidt ongeveer dezelfde families van getallen als die in de wiskunde:
gehele getallen, kommagetallen, breuken, enzovoorts.

ℝ
getal
	Dit is de set met alle reëele getallen.
	0.2, -4, 0, 1/3 vallen hier allen onder.

ℤ
int
geheel-getal
	Kort voor "integer" is dit de set met alle gehele getallen.
	Bijvoorbeeld 0, -3, 8, 1000.

nat
natuurlijk-getal
ℕ
	Dit zijn alle gehele getallen die niet negatief zijn, ook wel omschreven als
	mogelijke resultaten van een telling van een verzameling objecten.
	Bijvoorbeeld 1, 3, 0, 999.

# Rekenen
+: getal, getal → getal
	Telt twee getallen op.

-: getal, getal → getal
	Trekt twee getallen van elkaar af.

-: getal → getal
	Min een getal.

·: getal, getal → getal
	Vermenigvuldigt twee getallen met elkaar.

Σ: getal... → getal
	Neemt de som van een verzameling getallen.

∏: getal... → getal
	Neemt het product van een verzameling getallen.

%: getal
	Neem een getal gedeeld door 100.
	Schrijf als "25%"

^: a:getal, b:getal → getal
	Neem a tot de macht b.

\#: getal → getal
	Neem de absolute waarde van een getal.
	Kan ook geschreven worden als "|a|"

mod: getal, getal → getal
	Neemt de modulo van twee getallen,
	oftewel de rest van a gedeeld door b.

max: getal, getal → getal
	Neemt de grootste van twee getallen.

min: getal, getal → getal
	Neemt de kleinse van twee getallen.

int: getal → int
	Rond het getal af naar beneden.


# Trigonometrie
τ: getal
	De omtrek van een cirkel met straal 1.
	Ook wel gelijk aan twee keer pi.

sin: getal → -1 tot 1
	Neem de sinus van een getal.

cos: getal → -1 tot 1
	Neem de cosinus van een getal.

sincos: getal → getal, getal
	Neem de sinus en cosinus van een getal.

atan: getal, getal → -pi tot pi
	Neem de atan2 van een getal.

tan: getal → getal
	Neem de tangens van een getal.

# Existentieel
∐: maplet... → functie
	Maak een functie van een collectie maplets.

⇒: (cond: bit, obj) → obj | niets
	Is obj als cond waar is, of anders "niets".
	"als c dan e" is syntactische suiker voor "c ⇒ e"
	"e als c" is syntactische suiker voor "c ⇒ e"

⇒: (cond: bit, obj, alt) → obj
	Is obj als cond waar is, is anders "alt".
	"als c dan e anders f" is syntactische suiker voor "⇒(c, e, f)"

misschien = iets | niets

|: a:misschien, b:misschien → iets
	Kiest a of b, afhankelijk van welke gedefinieerd is.
	Óf a óf b moet gedefinieerd zijn, anders is het een *runtime error*.


# Vergelijkingen
=: iets, iets → bit
	Of twee objecten gelijk zijn aan elkaar.

≠: iets, iets → bit
	Of twee objecten ongelijk zijn aan elkaar.

>: getal, getal → bit
	Of het eerste getal groter is dan de tweede.


# Logica
bit
	Dit is het booleaanse type dat "ja" (waar) of "nee" (onwaar) kan bevatten.

¬: bit → bit
niet: bit → bit
	Neemt de logische inverse van de invoer (ja ↦ nee, nee ↦ ja).

∧: bit, bit → bit
en: bit, bit → bit
	Logische "en"-functie. Is alleen waar als allebei de argumenten waar zijn.

∨: bit, bit → bit
of: bit, bit → bit
	Logische "of"-functie. Is alleen waar als minimaal een van de argumenten waar is.

noch: bit, bit → bit
	Is alleen waar als het eerste argument noch het tweede argument waar is.

xof: bit, bit → bit
	Is alleen waar als óf het eerste, óf het tweede argument waar is.

⋀: bit... → bit
EN: bit... → bit
	Logische conjunctie van alle argumenten.
	Is alleen waar als alle argumenten waar zijn.
	Bij nul argumenten is deze functie ook waar.

⋁: bit... → bit
OF: bit... → bit
	Logische disjunctie van alle argumenten.
	Is alleen waar als minimaal één van de argumenten waar is.
	Bij nul argumenten is deze functie niet waar.


# Verzamelingen
Taal heeft ingebouwde manieren om meerdere objecten te groeperen, zoals
sets, tupels en lijsten.

\#: verzameling → nat
|a|: verzameling → nat
	Tel het aantal elementen in een verzameling.

# Sets
Sets zijn verzamelingen waarbij elk object maar één keer kan voorkomen.
Taal heeft ingebouwde syntax voor het maken en manipuleren van sets:

{}: obj... → set
	Maak een nieuwe set gevuld met de argumenten.
	Schrijf als "{1, 2, 3}".
	Ook al komt een argument meerdere keren voor, in de set zal die maar
	één keer voorkomen.

∪: set, set → set
	Neem de unie/vereniging van twee sets.
	Resultaat bevat elementen die in één of beide sets zitten.

∩: set, set → set
	Neem de intersectie/doorsnede van twee sets.
	Resultaat bevat alleen elementen die in beide sets zitten.

⊂: set, set → set
	Is alleen waar als de eerste set een subset is van de tweede set.
	Oftewel als elk element uit de eerste set ook in de tweede set zit.

∖: set, set → set
	Neem alle elementen die wel in de eerste maar niet in de tweede set zitten.

-: set, set → set
	Neem alle elementen uit de eerste set min de elementen uit de tweede set.
	Impliceert dat de tweede set een subset van de eerste set is.

∈: obj, set → bit
	Of een object (obj) in de set zit.

⋃: set... → set
	Neem de vereniging van alle argumenten.

⋂: set... → set
	Neem de intersectie van alle argumenten.

tot: a:getal,b:getal → set int
	Genereer een bereik van a tot b. Het dubbelgeparametriseerde "tot(a,b)" representeert een interval van
	a tot b (exclusief b).


# Lijsten
Een lijst is een geordende verzameling elementen (ook wel vector, array of sequence genoemd). 

[]: obj... → lijst
	Maak een nieuwe lijst gevuld met de argumenten.
	Schrijf als "[1, 2, 3]".

||: lijst(A), lijst(A) → lijst(A)
	Concateneer twee lijsten, oftewel "plak ze achter mekaar".

..: A:int,B:int → lijst int
	Maak een lijst met gehele gallen van a tot b (exclusief b).


# Functies
Functies kun je indirect (`f(x,y) = x + y`) of direct (`x → x + 1`) definiëren.
Alle functies zijn puur en zonder zijeffecten. "tijd" is een impliciete parameter voor elke functie.

→: args,exp → (args → exp)
	Maak een functie die exp teruggeeft op basis van args.

∘: ((a → b), (b → c)) → (a → c)
	Componeer twee functies.
	Doe de eerste functie en geef het resultaat aan de tweede functie.
	f ∘ g = x → f(g(x))

^: (a → a), nat → (a → a)
	Componeer een functie een aantal keer met zichzelf.
	Elke functie nul keer gecomponeerd is de (getypeerde) identiteitsfunctie.

# Tijd
moment: getal
	Een specifiek tijdstip in de tijd.

tijdsduur: getal
	Een tijdsduur, in seconden.

tijdsinterval:
	Een interval tussen twee momenten.

nu: moment
	Het huidige moment.

start: moment
	Het moment waarop het programma startte.

looptijd: tijdsduur
	Een specifiek tijdstip in de tijd.
