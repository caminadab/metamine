toetsRechts = 0
toetsLinks = 0
toetsOmhoog = 0
toetsOmlaag = 0

links = [5+toetsRechts-toetsLinks,toetsOmhoog]
rechts = [15,0]
bal = [10,10]

scherm = [1280,1024]
veld = 20
links / veld = linksScherm / scherm
rechts / veld = rechtsScherm / scherm
bal / veld = balScherm / scherm

cirkels = [linksScherm, rechtsScherm, balScherm]
stdout = cat cirkels
