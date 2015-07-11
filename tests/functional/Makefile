# vim:noet:ts=4:
.PHONY: test test_ prepro asm bas all

all: test test_

diffbas:
	./test.py -d *.bas

test: prepro bin asm bas 

test_:
	./test_.py

prepro:
	./test.py *.bi

asm:
	./test.py *.asm

# This includes all .bas BASIC programs having a corresponding .asm
bas:
	./test.py *.bas

# This only includes all .bas BASIC programs having a
# corresponding .asm which starts by a digit.
basic_tests:
	./test.py [0-9]*.bas

bin:
	./test.py tzx_*.bas tap_*.bas

# Measures coverage using only basic tests
.PHONY: basic_coverage
basic_coverage:
	./coverage.sh [0-9]*.bas
	coverage html -d basic_coverage
	
.PHONY: coverage
coverage:
	./coverage.sh *.bas
	coverage html -d coverage

