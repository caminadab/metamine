Origine
=======

Voor het ontwerp van een nieuw onderliggend systeem kijken we eerst naar het idee achter processors, dan naar de praktijk, dan naar bestaande goede systemen.


Idee
----

Een processor verwerkt informatie, echter maar op een paar zeer gelimiteerde manieren: kopieren en wat wiskundige berekeningen. Interpreteren doet onze software en hardware: dit plaatje staat op het scherm, deze film is als volgt opgeslagen, deze data wordt verwerkt als geluid door de stereo. Tot hier in het verhaal staat vast in de hardware en vanaf hier zijn wij *vrij*!!!!

De meeste programmeurs kunnen de enorme vrijheid die geboden is niet bevatten en duiken snel achter hun favoriete vertrouwde claustrofobisch achterhaalde monolithische systeem. De systemen die ik bedoel zijn ontworpen om je meer vrijheid te geven door alles gemakkelijker te maken, maar nemen stiekem oogluikend heel erg veel rauwe simpliciteit, kracht en heerlijkheid weg, en geven je kunstmatige probleempjes terug die je een oppervlakkig goed gevoel geven als je ze oplost. Terwijl het harde werk verborgen zit achter alle camouflage-achtige muren die opgeworpen zijn door jarenlang geknutsel van een horde onderbetaalde overbestresste programmeurs. DE nummer 1 reden voor lelijke designs.



Genoeg geklaagd: tijd voor de oplossing.
Alle informatieverwerking is te zien als `out = f(in)`, dus we nemen dit als basis voor een taal. In theorie kan je hier alle programma's mee bouwen (**Turing-compleet**). Een programma dat de som berekent van de input wordt dan:

	s = sum(input)
	out = text(s)

Maar wat is *s*, *sum* en *input*? Als je in de wiskunde zegt `a = 10`, is `a` dan niet slechts een label of naamplaatje voor `10`? Kunnen we dit voorbeeld herschrijven tot

	text(sum(input))

Er is geen reden waarom dit niet zou kunnen, declaratief gezien. De Nieuwe Taal zou dus kunnen bestaan uit aan elkaar geklinkte functies.

### Functie
Ik hoor de extreem gefascineerde stemmen in jouw hoofd al zeggen: wat is een functie. Het is een mapping van nul of meer variabelen naar een of meer variabelen. *Plus* is bijvoorbeeld een functie die twee variabelen neemt en de som teruggeeft. MAARRRR wat als de variabelen geen nummer zijn maar een kilogram suiker dat op je kamer staat (mocht je dit in kunnen programmeren). De code is nu duidelijk ongeldig: blijkbaar kan een functie niet alles als invoer nemen maar slechts een groepering aan variabelen.

### Type
Toevallig hebben andere grote denkers dit ook bedacht en dit *type* genoemt: de functie *Plus* neemt twee variabelen van type *nummer* en sommeert ze. Een type is dus eigenlijk een *set* of *groep* aan waarden. Met deze terminol0gie is een functie slechts een transformator tussen verschillende groepen: *Plus* transformeert meerdere waarden naar een enkele waarde (in dit geval ook van type **getal**).

### Types Aan De Anabolen
De klassieke definitie definieert een aantal basistypen en houdt zich vervolgens afzijdig. Veelgebruikte typen zijn: getal, tekst, enum, lijst, of samengestelde. Het is niet mogelijk om bijv het type "even getal" te definieren, of "getal tussen 0 en 100", of "graden celsius", of "gebruikersnaam" (= tekst zonder spaties en hoofdletters). Natuurlijk kan je wel de suggestie hooghouden door een klasse te maken, maar wie doet dit nou in de praktijk voor zoiets als percentages?!

Oplettende lezertjes zullen opmerken dat dit extreem zonde is, want hoe meer er rigide is gedefinieerd, hoe makkelijker het is voor de compiler om fouten vroeg te detecteren aangezien de gebruiker dit niet hoeft te doen.

