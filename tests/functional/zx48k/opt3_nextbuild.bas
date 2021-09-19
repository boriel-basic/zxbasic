

sub UpdateSprite(ByVal x AS uinteger,ByVal y AS UBYTE,ByVal spriteid AS UBYTE,ByVal pattern AS UBYTE, _
                 ByVal mflip as ubyte,ByVal anchor as ubyte)
end sub


sub TileMap(byval address as uinteger, byval blkoff as ubyte, byval numberoftiles as uinteger,byval x as ubyte, _
            byval y as ubyte, byval width as ubyte, byval mapwidth as uinteger)
END SUB


TileMap($c000,0,2,0,0,16,2)
UpdateSprite(100,100,0,0,0,0)
