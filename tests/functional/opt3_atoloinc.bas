DIM level, key, doorstate, doorid, nfires as Ubyte
  level=1
  key=1
  doorstate=1
  doorid=0
  nfires=0
  key = 0

key = level
doorstate = level
doorstate = doorid
nfires = nfires + 1
level = key
nfires = doorstate

