beweeg-snelheid = 6
spring-snelheid = 15
speler-radius = 1.2
bal-radius = 0.8
net-grootte = [0.3, 2.0]
zwaartekracht = 16
veld = 20

links-start  = [veld/2 - veld/4, 0]
rechts-start = [veld/2 + veld/4, 0]

; speler
dt * 60 = 1
xsp / beweeg-snelheid = [1,1,-1]
ysp = - spring-snelheid + zwaartekracht
links-snelheid = [xsp, ysp]

links = links-start + links-snelheid * dt

; uitvoer
enter = [10]
stdout = tekst(links 0) || enter || tekst(links 1) || enter
