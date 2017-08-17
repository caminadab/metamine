value = int | text | dict | list
bvalue = bint | btext | bdict | blist
bdecode = bvalue >> value
bencode = value >> bvalue

; int
bint: data
i:int >> bint = 'i' || (i >> text) || 'e'
ic = bi:bint >> int 
#ib = find ic,'e'
ic[bi] = 

; tekst
btext: data
text >> btext = # text || ':' || text
bc = btext >> text
textlen = bc[0 .. find[b, ':']]
a = bc[(0 .. textlen) + #textlen + 1]

; dict
bdict: data
keys = text^int
bentry = key * value
bentries = bentry^int
dict = value[keys]
bdict = 'd' || concat bentries || 'e'

b: bdict
b['a'] = 3: int

; list
list = value^int
bitems = bvalue^int
blist = 'l' || concat bitems || 'e'

; zelfje
bencode 'hoi' = '3:hoi'
bencode 1,'a' = 'li1e1:a'
bencode 'hoi'['h'] = 'd1:h3:hoie'
test = 
