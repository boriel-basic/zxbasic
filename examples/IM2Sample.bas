' Example of the use of the IM2 library

' Including the IM2 library
#include "IM2.bas"

' We declare two variables to use inside IM2CallMyRoutine
' These variables must be global
' Time wasting counter
DIM im2_Counter AS UInteger
' Height of the horizon
DIM im2_Horizon AS UInteger = 400

' We call the subroutine Main
Main()


' - Main subroutine ---------------------------------------
SUB Main()
    CLS
    PRINT AT 23,0;"q - Up, a - Down, s - Stop";
    PRINT AT 0,0;"Height of the horizon:";
    ' We configure and start up the interruptions.
    IM2Start(@MyInterruptRoutine)

    ' Infinite loop
    DO
        ' Print the current horizon height
        PRINT AT 0,23;im2_Horizon;"  ";
        ' If we press "q", we raise the horizon.
        IF INKEY$ = "q" THEN
            ' We raise it as long as it is not 0
            IF im2_Horizon > 0 THEN
                ' Going up means less pause
                im2_Horizon = im2_Horizon - 1
            END IF
        ' Pressing "a" lowers the horizon.
        ELSEIF INKEY$ = "a" THEN
            ' Going down is to pause more
            im2_Horizon = im2_Horizon + 1
        ' Pressing "s" stops the interruptions.
        ELSEIF INKEY$ = "s" THEN
            IM2Stop()
            RETURN
        END IF
    LOOP
END SUB


' - This is our routine which is called at every interruption
' We can't do a lot of things inside
' Do not define local variables, do not use ROM,
' not to dawdle too much...
SUB FASTCALL MyInterruptRoutine()
    ' The sky is cyan
    BORDER 5
    ' We wait to change from heaven to earth
    FOR im2_Counter=0 to im2_Horizon
    NEXT im2_Counter
    ' The land is green
    BORDER 4
END SUB
