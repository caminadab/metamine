links = [5+toetsRechts-toetsLinks,toetsOmhoog]
rechts = [15,0]
bal = [10,10]

linksX = links.0
linksY = links.1

linksX / 20 = linksSchermX / 1280
linksY / 20 = linksSchermY / 1024

linksScherm = [linksSchermX, linksSchermY]
grechts = [rechts.0 / 20 * 1280, 1024 - rechts.1 / 20 * 1024]
gbal = [bal.0 / 20 * 1280, 1024 - bal.1 / 20 * 1024]

cirkels = [linksScherm, grechts, gbal]
stdout = cirkels
