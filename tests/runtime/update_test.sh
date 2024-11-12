#!/bin/bash

# ./run $1
NAME=$(basename -s .bas $1).z80
../../zxbc.py -f z80 -aB "$@" --debug-memory || exit 1
./update_test.py $NAME
mv $NAME.scr expected/$(basename -s .bas $1).tzx.scr
