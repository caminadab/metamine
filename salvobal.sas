rechts = [200,300]

balradius = 0.8
springsnelheid = 10
veldbreedte = 20

naarscherm = pos > [pos.0 / 20 * 1280, 1024 - pos.0 / 20 * 1024]

links = [5,0]
rechts = [15,0]
bal = [10,10]

glinks = [links.0 / 20 * 1280, 1024 - links.1 / 20 * 1024]
grechts = [rechts.0 / 20 * 1280, 1024 - rechts.1 / 20 * 1024]
gbal = [bal.0 / 20 * 1280, 1024 - bal.1 / 20 * 1024]
links = naarscherm [20,10]

cirkels = [glinks, grechts, gbal]
stdout = cirkels
