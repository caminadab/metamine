hoi = 'hoi'
num = big-endian & uint32
stream	=  [#hoi >> num]  ||  hoi

; bittorrent
dht[infohash] = {peer} | none
tracker[infohash] = {peer} | none

