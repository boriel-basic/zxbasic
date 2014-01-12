#!/bin/bash
# Coverage tests using python coverage

# TMP FILE used for output
TMPFILE=coverage.tmp.asm
ZXBASIC=~/src/spyder/zxbasic/zxb.py

# Sets virtualenv por testing
#source virtualenvwrapper.sh
#workon tests

# removes previous tests data if any
coverage erase

for f in $*; do
    coverage run -a $ZXBASIC --asm -o $TMPFILE $f
    rm -f $TMPFILE
done

# leave virtualenv
# deactivate

