' vim:ts=4:et:
' ---------------------------------------------------------
' 64 Characters wide PRINT Routine for ZX BASIC
' Contributed by Britlion
' ---------------------------------------------------------

#ifndef __PRINT64__
#define __PRINT64__

#pragma push(case_insensitive)
#pragma case_insensitive = TRUE

' Changes print coordinates.
SUB printat64 (y as uByte, x as uByte)
    POKE @p64coords,x
    POKE @p64coords+1,y
END sub

' Print given string at current position
SUB print64 (characters$ as String)
    asm
    PROC    ; Declares begin of procedure
            ; so we can now use LOCAL labels

    LD L,(IX+4)
    LD H,(IX+5) ; Get String address of characters$ into HL.

    ld a, h
    or l
    jp z, p64_END       ; Return if NULL string

    ; Load BC with length of string, and move HL to point to first character.
    ld c, (hl)               
    inc hl                   
    ld b, (hl)               
    inc hl                   

    ; Test string length. If Zero, exit.
    ld a, c                  
    or b                     
    jp z, p64_END            
           
    LOCAL examineChar       
    examineChar:
            ld a, (hl)               ; Grab the character
            cp 128                   ; too high to print?
            jr nc, nextChar          ; then we go to next.
           
            cp 22                    ; Is this an AT?
            jr nz, newLine           ; If not, hop to newLine routine.
            ex de, hl                ; Swap DE and HL
            and a                    ; Clear Carry
            ld hl, 2                 ;   
            sbc hl, bc               ; Can we Shorten our string length by 2? If not then at (y,x) doesn't make sense.
            ex de, hl                ; Swap DE and HL back
            jp nc, p64_END           ; If we went negative, there wasn't anything to AT to, so we return.
           
            inc hl                   ; Onto our Y co-ordinate
            ld d, (hl)               ; And load it into D
            dec bc                   ; Shorten our remaining string counter.
            inc hl                   ; Onto the X Co-ordinate
            ld e, (hl)               ; Load it into E
            dec bc                   ; Shorten our remaining string counter
            call p64_test_X          ; Make xy legal 60051 205 53  235
            jr p64_eaa3              ; Go to save coords 60054 24  11

    LOCAL newLine
    newLine:
            cp 13                    ; Is this a newline character? 60056 254 13
            jr nz, p64_isPrintable   ; If not, hop to testing to see if we can print this 60058 32  13
            ld de, (p64_coords)      ; Get coords 60060 237 91  68  235
            call p64_nxtLine         ; Go to next line.     

    LOCAL p64_eaa3
    p64_eaa3:
            ld (p64_coords), de      
            jr nextChar              

    LOCAL p64_isPrintable
    p64_isPrintable:
            cp 31                    ; Bigger than 31? 60073 254 31
            jr c, nextChar           ; If not, get the next one. 60075 56  7 
            push hl                  ; Save position 60077 229
            push bc                  ; Save Count   60078 197
            call p64_PrintChar       ; Call Print SubRoutine 60079 205 189 234
            pop bc                   ; Recover length count  60082 193
            pop hl                   ; Recover Position 60083 225

    LOCAL nextChar
    nextChar:
            inc hl                   ; Point to next character 60084 35
            dec bc                   ; Count off this character 60085 11
            ld a, b                  ; Did we run out? 60086 120
            or c                     
            jr nz, examineChar       ; If not, examine the next one 60088 32  193
            jp p64_END               ; Otherwise hop to END. 60090 201

    LOCAL p64_PrintChar
    p64_PrintChar:
            exx                      
            push hl                  ; Save HL' 60094 229
            exx                      
            sub 32                   ; Take out 32 to convert ascii to position in charset 60096 214 32
            ld h, 0                  
            rra                      ; Divide by 2 60100 31
            ld l, a                  ; Put our halved value into HL 60101 111
            ld a, 240                ; Set our mask to LEFT side 60102 62  240
            jr nc, p64_eacc          ; If we didn't have a carry (even #), hop forward. 60104 48  2 
            ld a, 15                 ; If we were ab idd #, set our mask to RIGHT side instead 60106 62  15

    LOCAL p64_eacc
    p64_eacc:
            add hl, hl               
            add hl, hl               
            add hl, hl               ; Multiply our char number by 8 60110 41
            ld de, p64_charset       ; Get our Charset position 60111 17  70  235
            add hl, de               ; And add our character count, so we're now pointed at the first
                                     ; byte of the right character. 60114 25
            exx                      
            ld de, (p64_coords)      
            ex af, af'               
            call p64_loadAndTest     
            ex af, af'               
            inc e                    
            ld (p64_coords), de      ; Put position+1 into coords 60126 237 83  68  235
            dec e                    
            ld b, a                  
            rr e                     ; Divide X position by 2 60132 203 27
            ld c, 0                  
            rl c                     ; Bring carry flag into C (result of odd/even position) 60136 203 17
            and 1                    ; Mask out lowest bit in A 60138 230 1 
            xor c                    ; XOR with C (Matches position RightLeft with Char RightLeft) 60140 169
            ld c, a                  
            jr z, p64_eaf6           ; If they are both the same, skip rotation. 60142 40  6 
            ld a, b                  
            rrca                     
            rrca                     
            rrca                     
            rrca                     
            ld b, a                  

    LOCAL p64_eaf6
    p64_eaf6:
            ld a, d                  ; Get Y coord 60150 122
            sra a                    
            sra a                    
            sra a                    ; Multiply by 8 60155 203 47
            add a, 88                
            ld h, a                  ; Put high byte value for attribute into H. 60159 103
            ld a, d                  
            and 7                    
            rrca                     
            rrca                     
            rrca                     
            add a, e                 
            ld l, a                  ; Put low byte for attribute into l 60167 111
            ld a, (23693)            ; Get permanent Colours from System Variable 60168 58  141 92
            ld (hl), a               ; Write new attribute 60171 119
           
            ld a, d                  
            and 248                  
            add a, 64                
            ld h, a                  
            ld a, b                  
            cpl                      
            ld e, a                  
            exx                      
            ld b, 8                  

    LOCAL p64_eb18
    p64_eb18:
            ld a, (hl)               
            exx                      
            bit 0, c                 
            jr z, p64_eb22           
            rrca                     
            rrca                     
            rrca                     
            rrca                     

    LOCAL p64_eb22
    p64_eb22:
            and b                    
            ld d, a                  
            ld a, (hl)               
            and e                    
            or d                     
            ld (hl), a               
            inc h                    
            exx                      
            inc hl                   
            djnz p64_eb18            
            exx                      
            pop hl                   
            exx                      
            ret                      

    LOCAL p64_loadAndTest
    p64_loadAndTest:
            ld de, (p64_coords)          

    ; SubRoutine to go to legal character position. (60213)
    LOCAL p64_test_X
    p64_test_X:
            ld a, e                   ; Get column from e
            cp 64                     ; more than 64 ?
            jr c, p64_test_Y          ; If not, then jump over nextline

    LOCAL p64_nxtLine
    p64_nxtLine:
            inc d                     ; Move down 1
            ld e, 0                   ; reset x co-ord to zero 

    LOCAL p64_test_Y
    p64_test_Y:
            ld a, d                   ; get Y co-ord
            cp 24                     ; Past 24?
            ret c                     ; Return if not.
            ld d, 0                   ; Rest y co-ord to top of screen. 
            ret                       ; Return.
    end asm
    p64coords:
    asm
    LOCAL p64_coords;
    p64_coords:
           defb 64;  X Coordinate store  60228 64
           defb 23;  Y Coordinate Store 60229 23

    LOCAL p64_charset
    p64_charset:         
            DEFB 0,2,2,2,2,0,2,0                   ; Space !
            DEFB 0,80,82,7,2,7,2,0                 ; "" #
            DEFB 0,37,113,66,114,20,117,32         ; $ %
            DEFB 0,34,84,32,96,80,96,0             ; & '
            DEFB 0,36,66,66,66,66,36,0             ; ( )
            DEFB 0,0,82,34,119,34,82,0             ; * +
            DEFB 0,0,0,0,7,32,32,64                ; , -
            DEFB 0,1,1,2,2,100,100,0               ; . /
            DEFB 0,34,86,82,82,82,39,0             ; 0 1
            DEFB 0,34,85,18,33,69,114,0            ; 2 3
            DEFB 0,87,84,118,17,21,18,0            ; 4 5
            DEFB 0,55,65,97,82,84,36,0             ; 6 7
            DEFB 0,34,85,37,83,85,34,0             ; 8 9
            DEFB 0,0,2,32,0,34,2,4                 ; : ;
            DEFB 0,0,16,39,64,39,16,0              ; < =
            DEFB 0,2,69,33,18,32,66,0              ; > ?
            DEFB 0,98,149,183,181,133,101,0        ; @ A     Changed from   ;0,2,37,87,117,85,53,0             
            DEFB 0,98,85,100,84,85,98,0            ; B C
            DEFB 0,103,84,86,84,84,103,0           ; D E
            DEFB 0,114,69,116,71,69,66,0           ; F G
            DEFB 0,87,82,114,82,82,87,0            ; H I
            DEFB 0,53,21,22,21,85,37,0             ; J K
            DEFB 0,69,71,71,69,69,117,0            ; L M
            DEFB 0,82,85,117,117,85,82,0           ; N O
            DEFB 0,98,85,85,103,71,67,0            ; P Q
            DEFB 0,98,85,82,97,85,82,0             ; R S
            DEFB 0,117,37,37,37,37,34,0            ; T U
            DEFB 0,85,85,85,87,39,37,0             ; V W
            DEFB 0,85,85,37,82,82,82,0             ; X Y
            DEFB 0,119,20,36,36,68,119,0           ; Z [
            DEFB 0,71,65,33,33,17,23,0             ; \ ]
            DEFB 0,32,112,32,32,32,47,0            ; ^ _
            DEFB 0,32,86,65,99,69,115,0            ; £ a
            DEFB 0,64,66,101,84,85,98,0            ; b c
            DEFB 0,16,18,53,86,84,35,0             ; d e
            DEFB 0,32,82,69,101,67,69,2            ; f g
            DEFB 0,66,64,102,82,82,87,0            ; h i
            DEFB 0,20,4,53,22,21,85,32             ; j k
            DEFB 0,64,69,71,71,85,37,0             ; l m
            DEFB 0,0,98,85,85,85,82,0              ; n o
            DEFB 0,0,99,85,85,99,65,65             ; p q
            DEFB 0,0,99,84,66,65,70,0              ; r s
            DEFB 0,64,117,69,69,85,34,0            ; t u
            DEFB 0,0,85,85,87,39,37,0              ; v w
            DEFB 0,0,85,85,35,81,85,2              ; x y
            DEFB 0,0,113,18,38,66,113,0            ; z {
            DEFB 0,32,36,34,35,34,36,0             ; | {
            DEFB 0,6,169,86,12,6,9,6               ; ~ (c)

LOCAL p64_END
    p64_END:
    ENDP
    end asm

    end sub

#pragma pop(case_insensitive)

#endif

