# About


## About the Boriel BASIC Project

Boriel BASIC (formerly known as _ZX BASIC_ and _Boriel ZX BASIC_) is a [BASIC](https://en.wikipedia.org/wiki/BASIC) ''cross compiler''.
It will compile BASIC programs (in your PC) for your [ZX Spectrum](https://en.wikipedia.org/wiki/Sinclair_ZX_Spectrum).
Boriel BASIC is an <abbr title="Software Development Kit">SDK</abbr> entirely written in [python](https://www.python.org).
The SDK is implemented using the [PLY](https://www.dabeaz.com/ply/) (Python Lex/Yacc) compiler tool.
It translates BASIC to Z80 assembler code, so it is easily portable to other Z80 platforms (Amstrad CPC, MSX).
Other non-Z80 targets could also be available in the future.

Boriel BASIC syntax tries to maintain as much compatibility as possible to that of
[Sinclair BASIC](https://en.wikipedia.org/wiki/Sinclair_BASIC), but it also has many new features, mostly taken from
[FreeBASIC](https://www.freebasic.net/wiki) dialect.

### Platform Availability

Boriel BASIC is available _natively_ for Windows (32bit and 64bit) and Linux (x64). For other platforms (i.e. Mac OS)
you will need to have Python 3.12+ installed in your computer and download the version _with Python scripts_ from
the [Archive](archive.md) page.
