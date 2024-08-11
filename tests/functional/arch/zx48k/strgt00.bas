LET a$ = ""
LET b$ = "x"

LET c = (a$ > b$)
LET c = (a$ > "")
LET c = ("x" > b$)
LET c = (b$ > (a$ + "x"))
LET c = ((a$ + "x") > b$)

POKE c, 0
