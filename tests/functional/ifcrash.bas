IF KEYSPACE then
    if keyspacepressed=0 then
        if nfires>0 and fire=0 then
            poke nsfx,3
            nfires=nfires-1
            a = 1
            keyspacepressed=1
        end if
    end if
else
    keyspacepressed=0
end if
