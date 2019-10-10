welkom		Welkom
kop1			Een nieuwe programmeertaal.
kop2			Declaratief en intuïtief.
taalvlag	en.svg
taallink	/en
overkop		Wat
over1			Taal is een nieuwe manier van ontwikkelen. Schrijf snel declaratieve code in de vorm van simpele vergelijkingen en maak je geen zorgen meer over moeilijke libraries, frameworks of andere standaard programmeerbeslommeringen.
over2			Control flow wordt door de compiler uitgerekent. Hierdoor kun je modulairdere code schrijven, die bovendien veilig en snel is.
over3			Aangezien alles 'live' is hoef je niet zelf in de weer met callbacks, hooks of threads: als je een interface een lijst van verbonden clients laat weergeven zal deze standaard live worden geupdate.
qena			Q&A
q1hoe			Hoe werkt het?
a1web			Een webservice vertaalt je code naar javascript. Je computer/mobiel draait vervolgens de javascript lokaal.
vraag			Vraag!
vraagverz	Vraag verzonden
stelvraag	Stel je vraag...
xdemo1			planeten := []\nzonnen := [ zon ]\nzon = ((9, 5), 0.3)\n\n; planeet = (pos,rad,vel)\nnieuweplaneet = (muis.pos, 0.13, (0,0.01))\n\nals muisKlik dan\n\tplaneten := planeten' ‖ [nieuweplaneet]\neind\n\nals planeten' en ¬ muisKlik dan\n\tplaneten := planeten' map beweeg\neind\n\nvplus = v1,v2 → v1₀+v2₀,v1₁+v2₁\nvmin = w1,w2 → w1₀-w2₀,w1₁-w2₁\nvmul = u1,u2 → u1₀·u2₀,u1₁·u2₁\nvafstand = a,b → ((a₀-b₀)²+(a₁-b₁)²)^0.5\n\n; zwaartekracht\ng = 0.0001 / r²\nr = vafstand(pos, zon₀)\n\nrichting = atan (pos vmin zon₀)\ngrav = ((zon₀) vmin pos) vmul (g,g)\nbeweeg = (pos,rad,vel) → (pos vplus vel),rad,(vel vplus grav)\nuit = canvas((planeten ‖ zonnen) map cirkel)
xdemo1x		; je moet altijd 'uit' definieren\nuit = "hoi"
xdemo2			; je kan variabelen maken\na = 3\nb = 2\nuit = a + b
xdemo3			; beweegbare cirkel (gebruik pijltjestoetsen)\nx := 10\ny := 5\nals toetsRechts dan x := x' + 0.1 eind\nals toetsLinks dan x := x' - 0.1 eind\nuit = canvas [ cirkel(x,y,1) ]
xdemo4			; paint programmaatje\n; teken met je muis\ncirkels := []\nuit = canvas cirkels\n\n; stipje bij de muis\nals muis.klik dan\n	cirkels := cirkels' ‖ [ cirkel(muis.pos, 0.1) ]\neind\n\n; haal ze weer weg met spatie\nals toetsSpatie dan\n	cirkels := cirkels' vanaf 1\neind\n
xdemo5			; simpele stopwatch\nuit = looptijd\n
xdemo6			; maak een timer\ntimer = 3 - int(looptijd)\nals timer > 0 dan\n\tuit = tekst(timer)\nanders\n\tuit = "Boem!"\neind
xdemo7			; cirkel (canvas is 18×10)\nr = looptijd\nc = cirkel(muis.x,muis.y,r)\nuit = canvas [c]\n\n
xdemo8			; PONG 2019\n\n; spelers\ny1 := 3.5\ny2 := 3.5\nw = 1 ; spelerbreedte\nh = 3 ; spelerhoogte\nxmin = 0\nxmax = 17.777 - w\nymax = 10 - h\n\n; bal\nbalx := 17.777 / 2\nbaly := 5\nbalvx := -0.01\n\nals 2 > 1 dan\n	balx := balx' + balvx'\neind\nals toetsSpatie dan\n	balx := 10\neind\n\n; toetsenbord rechts\nals toetsOmhoog en y1' < ymax dan y1 := y1' + 0.2 eind\nals toetsOmlaag en y1' > 0    dan y1 := y1' - 0.2 eind\n\n; toetsenbord links\nals toetsW en y2' < ymax dan y2 := y2' + 0.2 eind\nals toetsS en y2' > 0    dan y2 := y2' - 0.2 eind\n\n; sprites\nlinks = rechthoek(xmax, y1, 1, 3)\nrechts = rechthoek(xmin, y2, 1, 3)\nbal = cirkel(balx, baly, 1)\nscore = label(5, 5, "hoi")\n\n; canvas\nuit = canvas [ links, rechts, bal, score ]
xdemo9			; tel de getallen 1 t/m 1000 op\nuit = Σ 1 .. 1001
xdemo10		; mooie cirkels\nr = looptijd + n/2 + n/5 + n/9 + n/100\n\nf = n + sin(looptijd) → cirkel(n/1,g(n),abs(sin(3·r))·abs(2·sin(looptijd/100)))\ng = y → sin(0.4 · looptijd + y) + 4\n\ncirkels = (0..40) map f\nuit = canvas cirkels
xdemo11		; functiecompositie\ng = x → x + 1\nh = y → y / 2 ; typ een "→" met "->"\nf = g² ∘ h ∘ g² ; typ met "@" en "^2" \nuit = f(3)
xdemo12		; zeg een aantal keer "hoi"\naantal = int(looptijd)\nf = x → x ‖ " hoi"\nuit = (f^aantal)("groet:")
xdemo13		; letters a t/m j\nf(i) = i + \'a\'\nuit = (0 .. 10) map f
xdemo14		; neem van elke letter de volgende\nuit = "Iho" map (a → a + 1)

episch1		v = f(muis.pos, 20)\nuit = teken [v]\n\nals looptijd mod 1 < 1/2 dan\n\tf = vierkant\nanders\n\tf = cirkel\nend
; TUTORIAL 1.1 --- Taal\n; Taal werkt met objecten en feiten.\n; Een object is bijvoorbeeld "3" of "uit".\n; "3" is gewoon een getal,\n; "uit" is het uitvoerscherm.\n; Een feit is "uit = 3".\n; Dit brengt ons bij het eerste voorbeeld:\nuit = 3
demo1		; Je kan variabelen maken met "a = 2"\na = 2\nuit = a
demo2		; ook kan je "+" gebruiken\na = 2\nb = 3\nuit = a + b
demo3		; de keerfunctie (·) schrijf je met sterretje\na = 1111\nb = 1111\nuit = a · b
demo4		; een if-statement is ook een geldig feit.\n; In de if-statement kan je andere feiten\n; neerzetten.\n; Volgens mij kun je geen if-statements in\n; if-statements zetten\na = 21 / 8\nals a > 2 dan\n	uit = "21/8 > 2"\neind
demo5		; met "anders" kun je aangeven\n; welke feiten moeten gebeuren als\n;de voorwaarde (a > 3) niet voldaan is\na = 21 / 8\nals a > 3 dan\n	uit = "21/8 > 3"\nanders\n	uit = "21/8 < 3"\neind
demo6		; 1.2 --- Lijsten\n; een lijst is een rij aan waardes\nlijst = [1,2,3]\nuit = lijst
demo7		; je kan ze combineren met "‖" (typ ||)\na = [1,2]\nb = [3,4]\nuit = a ‖ b
demo8		; je kan het eerste element uit de lijst halen\n; met lijst(0), tweede met lijst(1), enz.\na = [1,2,3]\nuit = a(0)
demo9		; je kan ook "_0" typen om "₀" te krijgen.\n; a₀ is het eerste element uit a.\na = [1,2,3]\nuit = a₀
demo10		; met 0..10 krijg je een reeks van 0 tot 10.\n; NB: tót 10, dus 10 is uitgezonderd\nn = 10\nuit = 0 .. n
demo11		; met "i : 0..10" geef je aan dat "i" in de\n; lijst 0 tot 10 zit.\n; Hiermee kun je makkelijk lijsten vullen.\ni: 0..10\nuit(i) = 3 · i
demo11		; Met "×" (typ xx) maak je een cartesisch product\n; tussen lijsten.\na = 0..3\nb = 10..13\nuit = a × b
demo12		; 1.3 --- Tupels\n; Een tupel is een meervoud aan waardes,\n; bijvoorbeeld (2,3). Dit tupel bevat\n; de elementen 2 en 3.\n; Je kan ze gebruiken bijvoorbeeld\n; als positie.\nx = 9\ny = 5\nuit = (x, y)
demo13		; de elementen kan je bereiken net als\n; bij een lijst.\ni = 2\ntupel = (0,1,2)\nuit = tupel(i)
demo14		; 1.3 --- Functies\n; Tot nu toe hebben we standaardfuncties gebruikt\n; zoals plus en keer. We kunnen ook onze eigen\n; functies maken met "→".\n; f = x → x + 1\n; geeft aan dat f een functie is die "x" naar "x + 1"\n; mapt.\n; Dit betekent dat f(x) = x + 1.\n; Dus f(0) = 1, f(3) = f(4),  f(-100) = -99\nf = x → x + 1\nuit = f(3)
demo15		; Je kan functies aan elkaar linken met "∘"\n; (typ als apenstaartje)\n; "f ∘ g" betekent: doe eerst f, dan g.\n; wanneer "f = h ∘ g" dan is f(x) = g(h(x))\n; "sin ∘ cos" is dus een functie voor x\n; die de cosinus van de sinus van x returnt.\n; In dit voorbeeld voegt g 1 toe aan zijn invoer,\n; en h voegt twee toe.\ng = x → x + 1\nh = y → y + 2\nf = g ∘ h\nuit = f(0)
demo16		; hierzo wordt +1 eerst toegepast,\n; daarna ·2, dan nog een keer ·2.\n; Dus van links naar rechts.\n; dit is hetzelfde als\n; uit = plus(mul(mul(2))).\nmul = x → x · 2\nplus = y → y + 1\nf = plus ∘ mul ∘ mul\nuit = f(2)
demo17		; De standaardfuncties kun je gebruiken\n; door er haakjes omheen te zetten.\n; f = (+) is de plusfunctie\n; van het type (getal,getal) → getal.\n; (getal,getal) is een tupel met\n; twee getallen erin.\na = (1,2)\nuit = (+) a
demo18		; Je kan ze ook aan elkaar linken\nf = (+) ∘ (-)\nuit = f(1,2)
demo19		; 1.3 --- Functioneel\n; Sla dit hoofdstuk over als je geen\n; programmeerkennis hebt.\n; De functie "vouw" maakt een enkel\n; element van een lijst door ze \n; met een functie met elkaar samen te\n; voegen, van links naar rechts.\ngetallen = 1 .. 10\nuit = getallen vouw (+)
demo20		; je kan vouw gebruiken met (∘) om een lijst van\n; functies te linken:\nf = [(+), sincos, (·)]\ng = f vouw (∘)\nuit = g(2,3)
demo21		; De functie "map" voert een functie\n; op alle elementen van een collectie uit.\nlijst = [1,2,3]\nfn = x → x² ; typ met ^2\nuit = lijst map fn
demo22		; 1.3 --- Sets\n; Net als lijsten zijn sets objecten.\n; in een set kan elk object maar 1x voorkomen.\n; Schrijf als {1,2,3}\nuit = {1,2,3}
demo23		; Sets kun je samenvoegen met UNIE.\n; a UU b bevat alle elementen uit a en uit b.\na = {1,2}\nb = {2,3}\nuit = a UU b
demo24		; Om de doorsnede (gemeenschappelijke objecten)\n; te krijgen gebruik je "ℕ"\na = {1,2}\nb = {2,3}\nuit = a ℕ b
demo25		\n; 1.3 --- Tekst\n; Tekst is in taal een object als elk ander,\n; geschreven als "tekst".\nuit = "hoi"
demo26		; Tekst is een lijst van letters.\n; Losse letters schrijf je met 'x'.\nuit = 'x'
demo27		; Je kunt dus ook tekst te maken als volgt\nh = 'h'\no = 'o'\ni = 'i'\nuit = [h, o, i, i, i]
demo28		; met tekst(i) kun je bij de i'de letter\na = "hoi"\nuit = a(1)
demo29		; Met ‖ kon je lijsten samenvoegen:\n; dit werkt evengoed op tekst.\na = "euro"\nb = "pa"\nuit = a ‖ b
demo30		; met de functie "tekst" kun je andere objecten\n; naar tekst omzetten. "tekst(3)" is dus\n; "3" als tekst.\na = 2\nuit = "a=" ‖ tekst(a)
demo31		\n; 1.3 --- Liveheid\n; Sommige objecten veranderen tijdens de duur\n; van het programma.\n; "looptijd" is bijvoorbeeld het aantal seconden\n; sinds het programma is gestart.\nuit = looptijd
demo32		; je kunt deze waarden gewoon als elke andere waarde\na = 3 + looptijd · 2\nuit = tekst(a)
demo33		; "int" rond een getal af naar beneden\nn = int(looptijd)\ni: 0..n\nuit(i) = i²
demo34		; andere live waarden zijn beschikbaar met\n; "toetsLinks", "toetsRechts",\n; "toetsOmhoog", "toetsOmlaag",\n; "toetsW" etcetera.\n; Deze representeren je toetsenbord\n; toetsen: aan of uit.\nuit = [toetsLinks, toetsRechts]
demo35		; je kan ook met "toetsLinksBegin" alleen\n; het moment opvragen dat de toets ingedrukt\n; wordt\nuit = toetsLinksBegin
demo36		; 1.7 -- Variabelen\n; Tot nu toe hebben we functies en live waarden\n; gezien, maar nog geen makkelijke manier om\n; complexe variabelen te maken (zoals mario's\n; positie in Super Mario).\n;\n; Met "a := 0" maak je a variabel: aan het begin\n; wordt a eenmalig op nul gezet.\na := looptijd\nuit = a
demo37		; In if-statements kan je variabelen ook veranderen.\na := 0\nals toetsSpatieBegin dan\n	a := 1\neind\nuit = a
demo38		; Je kan naar een vorige kopie van een variabele\n; refereren met een enkele quote (a').\na := 0\nals toetsSpatieBegin dan\n	a := a' + 1\neind\nuit = a
demo39		; 1.9 --- Canvas\n; De functie "canvas" toont een canvas (interactief\n; gebied) met vormen erin getekend.\n; Hij neemt als argument een lijst van figuren.\n; De functie cirkel(positie, straal) is zo'n figuur.\n;\n; De standaardgrootte van het canvas is 17 7/9 × 10\npos = (9,5)\nstraal = 1\ncirk = cirkel(pos, straal)\nfiguren = [cirk]  ; lijst met 2 element\nuit = canvas(figuren)
demo40		; Geleerde technieken combinerende kunnen we nu makkelijk\n; tien cirkels tekenen\ni: 0..10\nfiguren(i) = cirkel((i,i), 0.5)\nuit = canvas(figuren)
demo41		; of tien cirkels naar de muis laten richten\ni: 0..10\nfiguren(i) = cirkel((muisX/i,muisY/i), 0.5/i)\nuit = canvas(figuren)\n
