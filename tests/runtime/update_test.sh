#!/bin/bash

# ./run $1
NAME=$(basename -s .bas $1).tzx
RUN=$(basename -s .bas $1)
rm -f "$NAME"
../../zxbc.py -TaB "$@" --debug-memory || exit 1
./update_test.py $NAME
mv $NAME.scr expected
