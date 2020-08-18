REM ----------------------------------------------------------------
REM Copyleft(k) 2017
REM yomboprime's UART library (https://github.com/yomboprime)
REM Ported to ZX Basic by boriel
REM License: MIT
REM ----------------------------------------------------------------


#ifndef ZXUNO_UART
#define ZXUNO_UART

#pragma push(string_base)
#pragma string_base = 0


#define UART_DATA_REG 250
#define UART_STAT_REG 251
#define UART_BYTE_RECEIVED_BIT 0x80
#define UART_BYTE_TRANSMITTING_BIT 0x40

#define ZXUNO_ADDR 64571
#define ZXUNO_REG 64827

DIM UARTpokeByte as UByte

REM The already read byte
DIM UARTbyteBuffer as UByte

REM If true, then there is a byte already received in the uart, waiting to be read
DIM UARTbitReceived as UByte


SUB UARTbegin
    DIM dummy as UByte
    REM Clears UART flag by reading the registers
    OUT ZXUNO_ADDR, UART_STAT_REG
    dummy = IN ZXUNO_REG
    OUT ZXUNO_ADDR, UART_STAT_REG
    dummy = IN ZXUNO_REG

    REM Clears the "byte received in the memory buffer" flag
    UARTpokeByte = 0
    REM Clears the bit "byte received in the UART"
    UARTbitReceived = 0
END SUB


SUB UARTwriteByte(ByVal value as UByte)
    DIM stat as UByte = 0
    OUT ZXUNO_ADDR, UART_STAT_REG
    
    WHILE stat bAND UART_BYTE_TRANSMITTING_BIT = UART_BYTE_TRANSMITTING_BIT
        stat = IN ZXUNO_REG
        IF stat bAND UART_BYTE_RECEIVED_BIT = UART_BYTE_RECEIVED_BIT THEN
            UARTbitReceived = 1
        END IF
    END WHILE

    REM Write the byte to the UART
    OUT ZXUNO_ADDR, UART_DATA_REG
    OUT ZXUNO_REG, value
END SUB


FUNCTION UARTwrite(ByVal buf as UInteger, ByVal length as UInteger) as UInteger
    REM Caution: Up to 65535 bytes. 0 not supported
    DIM i, max, endbuff as Uinteger

    LET endbuff = buf + length - 1
    FOR i = buf TO endbuff
        UARTwriteByte(PEEK i)
    NEXT i

    RETURN length
END FUNCTION


SUB UARTprint(ByVal s as String)
    FOR i = 0 TO LEN(s) - 1
        UARTwriteByte(CODE s(i))
    NEXT i
END SUB


SUB UARTprintln(ByVal s as String)
    UARTprint(s)
    UARTwriteByte(13)
    UARTwriteByte(10)
END SUB


FUNCTION UARTread as Integer
    REM This function looks without blocking to see if a byte has been received
    REM If so, returns the value (0..255)
    REM Otherwise returns -1
    
    DIM result as Integer
    IF UARTpokeByte THEN
        UARTpokeByte = 0
        RETURN UARTbyteBuffer
    END IF

    IF UARTbitReceived THEN
        UARTbitReceived = 0
        OUT ZXUNO_ADDR, UART_DATA_REG
        RETURN IN ZXUNO_REG
    ELSE
        OUT ZXUNO_ADDR, UART_STAT_REG
        IF IN ZXUNO_REG bAND UART_BYTE_RECEIVED_BIT THEN
            OUT ZXUNO_ADDR, UART_DATA_REG
            RETURN IN ZXUNO_REG
        END IF
    END IF

    RETURN -1
END FUNCTION


FUNCTION UARTreadBlocking as UByte
    DIM result as Integer
    DO
        result = UARTread()
    LOOP UNTIL result >= 0
    RETURN CAST(UByte, result)
END FUNCTION


FUNCTION UARTavailable as UByte
    IF UARTpokeByte OR UARTbitReceived THEN
        RETURN 1
    END IF
    
    DIM c as UInteger
    c = UARTread() 
    IF c < 0 THEN
        RETURN 0  ' No byte available
    END IF
    
    REM Store the read byte and return 1 as available
    UARTpokeByte = 1
    UARTbyteBuffer = CAST(UByte, c)
    RETURN 1
END FUNCTION


FUNCTION UARTpeek as Integer
    REM read an available byte without consuming it 
    REM returns -1 if no byte available
    DIM c as Integer
    IF UARTpokeByte THEN
        REM There's already a byte read in memory
        RETURN UARTbyteBuffer
    END IF

    c = UARTread()
    IF c >= 0 THEN
        REM Store the read byte and returns it
        UARTpokeByte = 1
        UARTbyteBuffer = CAST(UByte, c)
    END IF

    RETURN c
END FUNCTION


REM Returns time in ms with a precision of 1/50
FUNCTION UARTtime() as ULong
    DIM UARTclock as ULong AT 23672
    RETURN (UARTclock & 0x00FFFFFF) * 20
END FUNCTION


FUNCTION UARTparseInt(ByVal timeoutms as ULong) as Long
    DIM t0 as ULong
    DIM value as ULong = 0
    DIM numChars as UByte = 0
    DIM minusSign as UByte = 0
    DIM c as UByte
    DIM cint as Integer

    t0 = UARTtime()

    WHILE UARTtime() - t0 < timeoutms
        cint = UARTpeek()
        IF cint < 0 THEN
            CONTINUE WHILE
        END IF

        c = CAST(Ubyte, cint)
        IF c >= CODE("0") AND c <= CODE("9") THEN
            c = c - CODE("0")
            value = value * 10 + c
            cint = UARTread()
            numChars = numChars + 1
        ELSEIF c = CODE("-") AND numChars = 0 THEN
            minusSign = 1
            cint = UARTread()
            numChars = numChars + 1
        ELSEIF numChars > 0 THEN
            REM Correct number entered
            IF minusSign THEN
                value = -value
            END IF
            RETURN value
        ELSE
            REM skip non numeric char at beginning
            cint = UARTread()
        END IF
    END WHILE

    RETURN -1
END FUNCTION


FUNCTION UARTfind(ByVal s as String, ByVal timeoutms as ULong) as UByte
    DIM t0 as ULong
    DIM c as UByte
    DIM cint as UInteger
    DIM l as UInteger
    DIM numChars as UInteger = 0

    l = LEN(s)
    IF NOT l THEN
        RETURN 0
    END IF

    t0 = UARTtime()
    WHILE UARTtime() - t0 < timeoutms
        cint = UARTread()
        IF cint < 0 THEN
            CONTINUE WHILE
        END IF

        IF CODE(s(numChars)) = c THEN
            numChars = numChars + 1
            IF numChars = l THEN
                RETURN 1
            END IF
        ELSE
            numChars = 0
        END IF
    END WHILE

    RETURN 0
END FUNCTION


#undef ZXUNO_ADDR
#undef ZXUNO_REG

#pragma pop(string_base)

#endif

