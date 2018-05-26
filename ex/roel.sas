hoi = [104,111,105]


meting : tijd -> bit

meting-tijd = where(tijd.seconde, t -> t % 10 == 0)

stdout = concat meting(meting-tijd)
