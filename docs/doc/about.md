# About


## About the ZX BASIC Project

ZX BASIC is a [BASIC](http://en.wikipedia.org/wiki/BASIC) ''cross compiler''.
It will compile BASIC programs (in your PC) for your [ZX Spectrum](http://en.wikipedia.org/wiki/Sinclair_ZX_Spectrum).
ZX BASIC is an <abbr title="Software Development Kit">SDK</abbr> entirely written in [python](http://www.python.org).
The SDK is implemented using the [PLY](http://www.dabeaz.com/ply/) (Python Lex/Yacc) compiler tool.
It translates BASIC to Z80 assembler code, so it is easily portable to other Z80 platforms (Amstrad, MSX).
Other non Z80 targets could also be available in the future.

ZX BASIC syntax tries to maintain compatibility as much as possible with
[Sinclair BASIC](http://en.wikipedia.org/wiki/Sinclair_BASIC), it also have many new features, mostly taken from
[FreeBASIC](http://www.freebasic.net/wiki) dialect.

### Platform Availability
Since it is written in python, it is available for many platforms, like Windows, Linux and Mac.
You only need to have python installed on these. For windows, there also is an installable (.MSI) _compiled_
version, which does not need python previously installed.
