[![Build Status](https://travis-ci.org/boriel/zxbasic.svg?branch=master)](https://travis-ci.org/boriel/zxbasic)

ZX BASIC
--------

Copyleft (K) 2008, Jose Rodriguez-Rosa (a.k.a. Boriel) <http://www.boriel.com>

All files within this project are covered under de LGPL3-like LICENSE
(Read <http://www.gnu.org/licenses/lgpl.html>). 

You can create closed-source (even commercial ones!) programs with this compiler
(a mention to this tool will be welcome, though). But you are not allowed to 
release the compiler itself as a closed Source program.

If you modify *this* project (the compiler .py, .asm or whathever) files 
in any way you MUST publish the changes you made and submit your contribution
to the community under the same license.

-------------------------

DOCUMENTATION
-------------

This is a very little help file.

For DOCUMENTATION in English go to the ZX BASIC Wiki:
<http://www.zxbasic.net>

For help, support, updates meet the community at my forum:
<http://www.boriel.com/forum/zx-basic-compiler>


INSTALL
-------

Go to the ZXBasic download page <http://www.boriel.com/wiki/en/index.php/ZX_BASIC:Archive>
and get the version most suitable for you. 

These tools are completely written in python, so you will need a python
interpreter (available on many platforms). Just copy them in a directory of your
hoice and installation is done. :-)

For Windows users there is also a binary .MSI installation, which does not need
python installed.


QUICK START
-----------

For a quick start, just open a terminal in your PC (Windows) and type
`zxb` or `zxb.py` (OSX, Linux). You should see a zxbasic message.

Create a text file, `hello.bas` with the following content:

~~~~
10 CLS
20 PRINT "HELLO WORLD!"
~~~~

and compile it with:
~~~~
zxb -taB hello.bas
~~~~

If everything went well, a file named `hello.tap` should be created.
Open it with your favourite emulator (i.e. fuse) and see the result.

Congratulations! You're now ready to create compiled BASIC programs for
your machine. Check and compile the examples included in the examples/ folder
or go to the Wiki <http://zxbasic.net> for further info.

AKNOWLEDGEMENTS
---------------

These are some people who has contributed in a way or another. I consider
some of them co-authors (Britlion, LCD) of this project.

Thanks to:

* Andre Adrian [adrianandre AT compuserve.de] from which I ripped the 32 bits
  Z80 MULT and DIV routines.
  See: <http://www.andreadrian.de/oldcpu/Z80_number_cruncher.html>

* Matthew Wilson [matthew AT mjwilson.demon.co.uk] and 
  Andy [fract AT zx-81.co.uk] from comp.sys.sinclair for their help on ROM FP-CALC usage.

* Mulder <http://www.worldofspectrum.org/forums/member.php?u=1369> from World Of Spectrum
  for finding the nasty PRINT AT bug and the GTU8 bug.
  See: <http://www.worldofspectrum.org/forums/showthread.php?p=278416&posted=1#post278416>

* Compiuter <http://www.speccy.org/foro/memberlist.php?mode=viewprofile&u=73> from
  Speccy.org for finding a bug in PRINT OVER 1 routine.

* Britlion <http://www.boriel.com/forum/member/britlion/>
  for his HUGE contribution (both in optimizations, ideas and libraries).

* LCD <http://members.inode.at/838331/index.html>
  Author of the BorIDE, which has also made many contributions to the project.

* There are several more contributions (e.g. Thanks to them for their intensive testing!). And thank you all
  (the entire community) for your interest!

If you have contributed in some way to this project, please, tell me so I'll add you to this list.


