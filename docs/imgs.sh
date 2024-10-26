#!/bin/bash

for i in $(egrep -e 'png|gif' released_programs.md); do
    IMG=$(echo $i|sed -e 's/^!*\[\([^]]*\)\].*$/\1/')
    LIMG=$(echo $IMG| tr A-Z a-z)
    DEST=./img/games/$LIMG
    (ls $DEST 2>/dev/null) && continue 
    IMGPATH=$(find ~/migration/client6/web10/web/wiki/ -type f -name "240px-$IMG")
    if [[ "$IMGPATH" == "" ]]; then
       continue
    fi
    #echo "Image: $IMG => $IMGPATH"
    cp -v $IMGPATH $DEST
done

