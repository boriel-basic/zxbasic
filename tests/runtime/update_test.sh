#!/bin/bash

# ./run $1
NAME=$(basename -s .bas $1).z80
RUN=$(basename -s .bas $1)
rm -f "$NAME"
../../zxbc.py --sna -aB "$@" --debug-memory || exit 1
snapconv "$RUN.sna" "$NAME"
./update_test.py $NAME
# mv $NAME.scr expected
