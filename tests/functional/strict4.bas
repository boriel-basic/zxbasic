#pragma strict=true

SUB goodsub(a as Ubyte, b as UInteger)
END SUB

REM no error: no param missing type
REM error: param missing type
SUB anysub(a as UByte, b)
END SUB

