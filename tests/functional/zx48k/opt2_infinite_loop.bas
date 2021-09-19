REM This was causing an infinite loop.

DIM kill as Ubyte

sub fastcall bulletcuchillo()
  if kill then
    return
  end if
endbulletcuchillo:
end sub

DIM dummy as Uinteger
dummy = @bulletcuchillo
