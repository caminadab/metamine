Elk programma bestaat uit een set feiten. Deze feiten worden soms pas bekend tijdens het uitvoeren van het programma (gebruikersinvoer, netwerkpakketten, zware berekeningen, enz). Dit zodat de vertaler zoveel mogelijk informatie kan deduceren.

# Netwerk
****udp-uit* is een multiset van alle netwerkpakketten die je programma ooit gaat sturen. Elk pakket is in de vorm van (adres-van, adres-naar, inhoud). Dit is een multiset omdat elk pakket meerdere keren kan voorkomen - de vertaler houdt ze uit elkaar. *udp-uit* is niet gemodelleerd als lijst van pakketten omdat er geen expliciete volgorde in de pakketten zit: als de **hardware** het toeliet zou je meerdere pakketten tegelijk kunnen sturen.

Als je wil dat je pakket pas na 3 seconden wordt verstuurd moet je het feit dat *udp-uit* jouw pakket bevat pas na 3 seconden bekend maken:

    pakket = (zelf,ander,"hoi")
    (nu > 3) => pakket : udp-uit

of

    (nu = 3) => pakket := udp-uit
