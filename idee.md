# CSS
Cascerende Property Waarden ;)

# Inc
Incrementeel verwerken van vglkngen

# Scoop
Fysiek scoop pakkend

# X veranderd naar invoer over tijd
	
	; salvobal.def.sas
	beeld = 0 .. oneindig
	tijd = beeld / 60 ; kan zijn tijd: seconde
	toets.rechts = tijd -> aan; per beeld en toets: ja of nee?
	toets.rechts.code = 69, toets.code
	toets.rechts = 69 : toets.code
	toets.links = 72 : toets.code ; naamruimte

	; test
	beeld = 3
	toets.rechts en beeld = 30 => (file 'hoi.sas' = 'Hoppa')
	als toets.rechts en beeld = 30
		bestand 'hoi.sas' = 'Hoppa'

	; salvobal.init.sas
	beweeg-snelheid = 6
	spring-snelheid = 15
	speler-radius = 1.2
	bal-radius = 0.8
	net-grootte = [0.3, 2.0]
 
	; 1 speler
	speler.
		dx / beweeg-snelheid = toets.rechts - toets.links
		dy = grond * spring-snelheid - zwaartekracht
		x = som dx ; integraal
		y = som dy ; ook

	; overgeslagen!:
	; precisie
	; tijd
