#Identifier


Identifiers are used in your ZX BASIC program to define ''variable names'', ''function names'', ''subroutine names'' and ''[labels](labels.md)''. ZX Basic identifiers **must** start with a letter (a..z / A..Z) followed by an arbitrary number of letters and or digits. Original Sinclair BASIC allows spaces within variable names, but ZX BASIC <u>does not</u> (in fact, I found it a bit confusing!) 

Some identifiers are **reserved words**. Most of them are either BASIC ''statements'' or ''functions''. Functions return a value to be used in an ''expression'' whilst statements do not. 

Note that there are a number of common statements that you may find in ZX BASIC programs that are not technically reserved words, but library functions. Some of the internal libraries form functions that may overlap with your subroutine and function names (such as POS). So while they may not be technically reserved, you should consider the library function names as ones you should avoid. Also, some Sinclair Basic statements are implemented as library functions, so you should be especially aware of identifiers of this type, such as INPUT, POINT and ATTR.

## Reserved Identifiers  

The following identifiers are ''reserved words'', and can't be used as variables, functions or labels. Reserved identifiers are ''case insensitive'' (it doesn't matter whether you write them in upper or lower case letters, or a mix of them). So **PRINT**, **print** and **PrInT** means all the same in ZX BASIC. On the other hand, non-reserved words can be either case sensitive or not (depending on the [options](options.md)) in effect. 

Identifiers shown in bold are taken from the Sinclair BASIC (beware their meaning here might be different, however). Some of them has been marked as ''statements'', ''functions'' or ''operators'': 

* **[ABS](abs.md)** **(function)**
* **[ACS](acs.md)** **(function)** 
* **[AND](operators#logical_operators.md)** **(operator)** 
* [ALIGN](align.md) **(special)** 
* [ASM](asm.md) **(special)** 
* **[ASN](asn.md)** **(function)** 
* **[AT](at.md)** 
* **[ATN](atn.md)** **(function)** 
* **[bAND](bitwiselogic.md)** **(operator)**
* **[bNOT](bitwiselogic.md)** **(operator)**
* **[bOR](bitwiselogic.md)** **(operator)**
* **[bXOR](bitwiselogic.md)** **(operator)**
* **[BEEP](beep.md)** **(statement)** 
* [BOLD](bold.md) 
* **[BORDER](border.md)** **(statement)** 
* **[BRIGHT](bright.md)** **(statement)** 
* [ByRef](byref.md) 
* [ByVal](byval.md) 
* [CAST](cast.md) **(function)** 
* **[CHR](chr.md)** **(function)** (can also be written as **CHR$**) 
* **[CIRCLE](circle.md)** **(statement)** 
* **[CLS](cls.md)** **(statement)** 
* **[CODE](code.md)** **(function)** 
* [CONST](const.md) 
* **[CONTINUE](continue.md)** **(statement)** 
* **[COS](cos.md)** **(function)** 
* **[DECLARE](declare.md)** **<modifier>**
* **[DIM](dim.md)** **(statement)** 
* [DO](do.md) **(statement)** 
* **[DATA](data.md)** **(statement)** 
* **[DRAW](draw.md)** **(statement)** 
* [ELSE](if.md) 
* [ELSEIF](if.md) 
* [END](end.md) 
* [EXIT](exit.md) **(statement)** 
* **[EXP](exp.md)** **(function)** 
* [FastCall](fastcall.md) 
* **[FLASH](flash.md)** **(statement)** 
* **[FOR](for.md)** **(statement)** 
* [FUNCTION](function.md) 
* **[GO TO](goto.md)** o[GOTO](goto.md)]] **(statement)** 
* **[GO SUB](gosub.md)** o[GOSUB](gosub.md)]] **(statement)**
* **[IF](if.md)** **(statement)** 
* **[IN](in.md)** **(function)** 
* **[INK](ink.md)** **(statement)** 
* **[INKEY](inkey.md)** **(function)** (can also be written as **INKEY$**) 
* **[INT](int.md)** **(function)** 
* **[INVERSE](inverse.md)** **(statement)** 
* [ITALIC](italic.md)
* [LBOUND](lbound.md) **<function;>** 
* **[LET](let.md)** **(statement)** 
* **[LEN](len.md)** **(function)** 
* **[LN](ln.md)** **(function)** 
* **[LOAD](load.md)** **(statement)** 
* [LOOP](do.md) **(statement)** 
* [MOD](operators#arithmetic_operators.md) **(operator)** 
* **[NEXT](for.md)** **(statement)** 
* **[NOT](operators#logical_operators.md)** **(operator)** 
* **[OR](operators#logical_operators.md)** **(operator)** 
* **[OVER](over.md)** **(statement)** 
* **[OUT](out.md)** **(statement)** 
* **[PAPER](paper.md)** **(statement)** 
* **[PAUSE](pause.md)** **(statement)** 
* **[PEEK](peek.md)** **(function)** 
* **[PI](pi.md)** **<constant>** 
* **[PLOT](plot.md)** **(statement)** 
* **[POKE](poke.md)** **(statement)** 
* **[PRINT](print.md)** **(statement)** 
* **[RANDOMIZE](randomize.md)** **(statement)** 
* **[READ](read.md)** **(statement)** 
* **[REM](comments.md)** **(commentary)** (can also be written as ') 
* **[RESTORE](restore.md)** **(statement)** 
* **[RETURN](return.md)** **(statement)** 
* **[RND](rnd.md)** **(function)** 
* **[SAVE](load.md)** **(statement)** 
* **[SGN](sgn.md)** **(function)** 
* [SHL or <<](shl.md) (operator) 
* [SHR or >>](shl.md) (operator) 
* **[SIN](sin.md)** **(function)** 
* **[SQR](sqr.md)** **(function)** 
* [StdCall](stdcall.md) 
* **[STEP](for.md)**
* **[STOP](stop.md)**
* **[STR](str.md)** **(function)** (Can also be written as **STR$**) 
* **[SUB](sub.md)** 
* **[TAN](tan.md)** **(function)** 
* **[THEN](if.md)** 
* **[TO](to.md)** 
* [UBOUND](ubound.md) **(function)** 
* [UNTIL](do.md) **(statement)** 
* **[VAL](val.md)** **(function)** 
* **[VERIFY](load.md)** **(statement)** 
* [WEND](while.md) **(statement)** 
* [WHILE](while.md) **(statement)**
* **[XOR](operators#logical_operators.md)** **(operator)**

##Inbuilt library Functions
You should also avoid defining (with a SUB or FUNCTION command) routines with the following names, as they are available in the internal library for your use, though you are almost certainly going to need to use #include before using them. Note that some Sinclair Basic words are listed here. Some Freebasic commands are also available through #include options for compatibility with freebasic.

* [ASC (Library Function)](asc.bas.md) **(function)** 
* **[ATTR (Library Function)](attr.md)** **(function)** 
* **[CSRLIN (Library Function)](csrlin.md)** **(function)** 
* [HEX (Library Function)](hex.md) **(function)** 
* [HEX16 (Library Function)](hex.md) **(function)**  
* **[INPUT (Library Function)](input.md)** **(function)** 
* **[GetKey (Library Function)](keys.bas.md)** **(function)** 
* **[MultiKeys (Library Function)](keys.bas.md)** **(function)** 
* **[GetKeyScanCode (Library Function)](keys.bas.md)** **(function)** 
* **[LCase (Library Function)](lcase.md)** **(function)** 
* **[UCase (Library Function)](ucase.md)** **(function)** 
* **[POINT (Library Function)](point.md)** **(function)** 
* **[POS (Library Function)](pos.md)** **(function)** 
* **[print42 (Library Subroutine)](print42.bas.md)** **(sub)** 
* **[printat42 (Library Subroutine)](print42.bas.md)** **(sub)** 
* **[print64 (Library Subroutine)](print64.bas.md)** **(sub)** 
* **[printat64 (Library Subroutine)](print64.bas.md)** **(sub)** 
* **[SCREEN(Library Function)](screen.md)** **(function)** 
