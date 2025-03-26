dim pldx as ubyte

sub ReadKeys()
    if pldx or (pldx and %1) then
        pldx = 1
    endif
end sub
