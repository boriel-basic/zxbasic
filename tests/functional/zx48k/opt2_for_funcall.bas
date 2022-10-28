main()

function saludar(x as Uinteger) as Uinteger
  return x + 1
end function

sub main()
  dim i, result as uinteger
  for i = 1 to 2
    result = saludar(i)
  next
end sub
