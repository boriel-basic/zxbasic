.PHONY: test test_ prepro asm bas all

all: test test_

diffbas:
	./test.py -d *.bas

test: prepro asm bas

test_:
	./test_.py

prepro:
	./test.py *.bi

asm:
	./test.py *.asm

bas:
	./test.py *.bas


