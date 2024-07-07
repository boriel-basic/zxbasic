dim r(0 to 6) as ulong => {40000, 35000, 30000, 25000, 20000, 15000, 10000}

dim score as ulong = 70000

sub main(scr as ulong)
  dim i as Uinteger = 0
  r(i) = 70000
  r(i) = score
  r(i + 1) = scr
end sub

main(80000)

poke 0, r(0)
