DIM face, modoi, ds1 as Ubyte

function choque() as UByte
            if choque=1
                if face=0 then
                    if ds1<=0 then
                        face=1  ' FACE
                        modo=3  ' GIRA IZDA
                    else
                        face=3
                        modo=4  ' GIRA DCHA
                    end if
                end if

            elseif choque=8
                if face=3 then
                    if ds2<=0 then
                        face=2
                        modo=4
                    else
                        face=0
                        modo=3
                    end if
                end if

            elseif choque=3
                if face=0 then
                    face=3
                    modo=4
                'end if

                elseif face=1 then
                    face=2
                    modo=3
                end if

            elseif choque=6
                if face=1 then
                    face=0
                    modo=4
                'end if

                elseif face=2 then
                    face=3
                    modo=3
                end if

            elseif choque=12
                if face=2 then
                    face=1
                    modo=4
                'end if

                elseif face=3 then
                    face=0
                    modo=3
                end if

            elseif choque=9
                if face=0 then
                    face=1
                    modo=3
                'end if

                elseif face=3 then
                    face=2
                    modo=4
                end if

            elseif choque=7
                if face=3 then
                    goto finish
                end if

                if face=2 then
                    modo=3
                else
                    modo=4
                end if
                face=3

            elseif choque=14
                if face=0 then
                    goto finish
                end if

                if face=3 then
                    modo=3
                else
                    modo=4
                end if
                face=0

            elseif choque=13
                if face=1 then
                    goto finish
                end if

                if face=2 then
                    modo=3
                else
                    modo=4
                end if

                face=1

            elseif choque=11
                if face=2 then
                    goto finish
                end if

                if face=3 then
                    modo=4
                else
                    modo=3
                end if

                face=2

            elseif choque=5

                if face=0 then
                    if ds1<=0 then
                        face=1
                        modo=3
                    else
                        face=3
                        modo=4
                    end if
                elseif face=2 then
                    if ds1<=0 then
                        face=1
                        modo=4
                    else
                        face=3
                        modo=3
                    end if
                end if

            elseif choque=10

                if face=1 then
                    if ds2<=0 then
                        face=2
                        modo=3
                    else
                        face=0
                        modo=4
                    end if
                elseif face=3 then
                    if ds2<=0 then
                        face=2
                        modo=4
                    else
                        face=0
                        modo=3
                    end if
                end if
            end if
end function
finish:
choque

