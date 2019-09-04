welkom		Welkom
kop1			Een nieuwe programmeertaal.
kop2			Niet voor machines maar voor mensen.
overkop		Wat
over1			Taal is een nieuwe manier van ontwikkelen. Schrijf snel declaratieve code in de vorm van simpele vergelijkingen en maak je geen zorgen meer over moeilijke libraries, frameworks of andere standaard programmeerbeslommeringen.
over2			Control flow wordt door de compiler berekent. Hierdoor kun je modulairdere code schrijven, die bovendien veilig en snel is.
over3			Aangezien alles 'live' is hoef je niet zelf in de weer met callbacks, hooks of threads: als je een interface een lijst van verbonden clients laat weergeven zal deze standaard live worden geupdate.
qena			Q&A
q1hoe			Hoe werkt het?
a1web			Een webservice vertaalt je code naar javascript. Je computer/mobiel draait vervolgens de javascript lokaal.
vraag			Vraag!
vraagverz	Vraag verzonden
stelvraag	Stel je vraag...
demo1			; je moet altijd 'uit' definieren\nuit = "hoi"
demo2			; je kan variabelen maken\na = 3\nb = 2\nuit = a + b
demo3			; beweegbare cirkel (gebruik pijltjestoetsen)\nx := 10\ny := 5\nals toetsRechts dan x := x' + 0.1 eind\nals toetsLinks dan x := x' - 0.1 eind\nuit = canvas [ cirkel(x,y,1) ]
demo4			; paint programmaatje\n; teken met je muis\ncirkels := []\nuit = canvas cirkels\n\n; stipje bij de muis\nals muisKlik dan\n	cirkels := cirkels' ‖ [ cirkel(muisX, muisY, 0.1) ]\neind\n\n; haal ze weer weg met spatie\nals toetsSpatie dan\n	cirkels := cirkels' vanaf 1\neind\n
demo5			; simpele stopwatch\nuit = looptijd\n
demo6			; maak een timer\ntimer = 3 - int(looptijd)\nals timer > 0 dan\n\tuit = tekst(timer)\nanders\n\tuit = "Boem!"\neind'
demo7			; cirkel (canvas is 18×10)\nr = looptijd\nc = cirkel(muisX,muisY,r)\nuit = canvas [c]\n\n; cirkeltoy (gebruik muis/touch)\nuit = canvas cirkels\ncirkels = (0..15) map f\nf = i → cirkel(muisX ^ (i/8), 5, i/4)
demo8			; PONG 2019\n\n; spelers\ny1 := 3.5\ny2 := 3.5\nw = 1 ; spelerbreedte\nh = 3 ; spelerhoogte\nxmin = 0\nxmax = 17.777 - w\nymax = 10 - h\n\n; bal\nbalx := 17.777 / 2\nbaly := 5\nbalvx := -0.01\n\nals 2 > 1 dan\n	balx := balx' + balvx'\neind\nals toetsSpatie dan\n	balx := 10\neind\n\n; toetsenbord rechts\nals toetsOmhoog en y1' < ymax dan y1 := y1' + 0.2 eind\nals toetsOmlaag en y1' > 0    dan y1 := y1' - 0.2 eind\n\n; toetsenbord links\nals toetsW en y2' < ymax dan y2 := y2' + 0.2 eind\nals toetsS en y2' > 0    dan y2 := y2' - 0.2 eind\n\n; sprites\nlinks = rechthoek(xmax, y1, 1, 3)\nrechts = rechthoek(xmin, y2, 1, 3)\nbal = cirkel(balx, baly, 1)\nscore = label(5, 5, "hoi")\n\n; canvas\nuit = canvas [ links, rechts, bal, score ]
demo9			; tel de getallen 1 t/m 1000 op\nuit = Σ 1 .. 1001'
demo10		; mooie cirkels\nr = looptijd + n/2 + n/5 + n/9 + n/100\n\nf = n + sin(looptijd) → cirkel(n/1,g(n),abs(sin(3·r))·abs(2·sin(looptijd/100)))\ng = y → sin(0.4 · looptijd + y) + 4\n\ncirkels = (0..40) map f\nuit = canvas cirkels
demo11		; functiecompositie\ng = x → x + 1\nh = y → y / 2 ; typ een "→" met "->"\nf = g² ∘ h ∘ g² ; typ met "@" en "^2" \nuit = f(3)
demo12		; zeg een aantal keer "hoi"\naantal = int(looptijd)\nf = x → x ‖ " hoi"\nuit = (f^aantal)("groet:")
demo13		; letters a t/m j\nf(i) = i + \'a\'\nuit = (0 .. 10) map f
demo14		; neem van elke letter de volgende\nuit = "Iho" map (a → a + 1)
