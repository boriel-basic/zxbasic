main()

function saludar(x as Uinteger) as Uinteger
  return x + 1
end function

sub main()
  dim i, result as uinteger
  i = 0
  while i < 2
    result = saludar(i)
    i = i + 1
  end while
end sub
