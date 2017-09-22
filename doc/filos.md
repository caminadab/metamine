SAS is een efficiente compleet declaratieve taal met een gezond typesysteem.


Functies
========
- programma's hoeven niet lineair geschreven te worden: "a = b and b = 3" mag gewoon.
- alle functies doen mee aan de pret: 'hoi' || x = 'hoiii' geeft x = 'ii'
- variabelen kunnen meerdere waarden tegelijk zijn: a = 1|2|3. Handig voor programma validatie
- assembly code generatie


IO
==
Webservers doen aan 'langzame executie': ze wachten op vele clients tegelijk. Geen callbacks, hooks, threads nodig.
In- en uitvoer wordt voorgesteld als oneindige datastroom die geleidelijk wordt gematerialiseerd.

Server die van elke client een tijdsduur t binnenkrijgt, vervolgens t seconden wacht voordat hij 'hoi' naar diezelfde client stuurt:

    sock = socket '0.0.0.0:10101'
		clients = sock.accept
		time = clients.in >> line >> int
		clients.out = 'hoi' >> after time
		clients.closed = clients.out.done


Errors
======

Alle errors zijn een subgroep van de booleaanse waarde 'onwaar'. Een bestand uitlezen is van het type data | file-not-found. Reguliere uitvoering gaat goed maar zodra er een ongeldige waarde wordt gevonden breekt de hel los.
