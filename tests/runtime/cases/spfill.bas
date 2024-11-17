' A demo for the Fill library with patterns!
' (c)2002(?) by Alvin Albretch
' Ported to ZX Basic by Paul Fisher (Britlion)

#Include <SP/Fill.bas>
#Include "lib/tst_framework.bas"

INIT("Testing SPFill...")
CIRCLE 128, 87, 87
SPFill(128, 87, USR "a")
REPORT_OK
