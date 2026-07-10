' ----------------------------------------------------------------------
' mcu.bas (zx81sd) — Comunicacion con el MCU del SD81 Booster
'
' Primitivas del protocolo + wrappers de los comandos del MCU.
' Los comandos con nombre propio (joy.bas, etc.) se apoyan en esta
' libreria.
'
' Protocolo (puertos $A7 datos / $AF reloj):
'   El bit 7 del puerto $AF es el reloj de sincronizacion: el MCU lo
'   invierte cuando ha procesado cada lectura/escritura del puerto de
'   datos $A7. Tras cada operacion en $A7 hay que esperar ese cambio
'   antes de la siguiente.
'
'   ATENCION: escribir CUALQUIER valor en $AF resetea el MCU (peligroso
'   si esta escribiendo en la SD). Esta libreria solo LEE $AF.
'
' Las transferencias de datos estan implementadas en ensamblador (son
' el camino critico de LOAD/SAVE/F_READ/F_WRITE); el BASIC solo prepara
' parametros y convierte codificaciones.
'
' Codificacion: los comandos de fichero/texto viajan en codigos de
' caracter ZX81 (el MCU los convierte internamente). Esta libreria
' convierte automaticamente desde ASCII. Excepciones ya en crudo:
' F_OPEN (ASCII), BINARY_SAY (alofonos) y JOY (codigos de tecla).
'
' Convencion de resultados: las funciones devuelven el byte de estado
' del MCU (0 = exito; ver tabla de errores del manual). Las que
' devuelven datos (McuLoad, McuPwd, ...) dejan el estado en la variable
' global McuStatus.
' ----------------------------------------------------------------------

#pragma once

#pragma push(explicit)
#pragma explicit = true

' Estado devuelto por el ultimo comando "con datos" (McuLoad, McuPwd...)
dim McuStatus as ubyte

' Resultado de McuFree() en KB
dim McuFreeTotalKb as ulong
dim McuFreeFreeKb as ulong

' ======================================================================
' PRIMITIVAS DEL PROTOCOLO (ASM)
' ======================================================================

' Envia un byte al MCU y espera a que lo procese.
sub fastcall McuSend(value as ubyte)
    asm
        PROC
        LOCAL WAIT
        ; A = value (convencion fastcall para ubyte)
        push bc
        ld   b, a           ; salva el dato
        in   a, ($AF)
        ld   c, a           ; C = estado previo del reloj (bit 7)
        ld   a, b
        out  ($A7), a       ; envia
    WAIT:
        in   a, ($AF)
        xor  c
        jp   p, WAIT        ; espera a que el bit 7 cambie
        pop  bc
        ENDP
    end asm
end sub

' Lee un byte del MCU (respuesta o status) y espera el toggle posterior.
function fastcall McuRecv() as ubyte
    asm
        PROC
        LOCAL WAIT
        push bc
        in   a, ($AF)
        ld   c, a           ; reloj previo
        in   a, ($A7)       ; lee el dato (provoca el toggle del MCU)
        ld   b, a
    WAIT:
        in   a, ($AF)
        xor  c
        jp   p, WAIT
        ld   a, b           ; devuelve el dato en A (fastcall ubyte)
        pop  bc
        ENDP
    end asm
end function

' Envia un bloque de memoria al MCU (un byte por transaccion de reloj).
' Bucle integramente en ASM: camino critico de SAVE / F_WRITE.
sub fastcall McuSendBlock(addr as uinteger, size as uinteger)
    asm
        PROC
        LOCAL LOOP, WAIT, DONE
        ; HL = addr (fastcall); pila: [ret][size]
        pop  de             ; DE = direccion de retorno
        pop  bc             ; BC = size
        push de             ; restaura el retorno

        ld   a, b
        or   c
        jr   z, DONE
    LOOP:
        in   a, ($AF)
        ld   e, a           ; E = reloj previo
        ld   a, (hl)
        out  ($A7), a
    WAIT:
        in   a, ($AF)
        xor  e
        jp   p, WAIT
        inc  hl
        dec  bc
        ld   a, b
        or   c
        jr   nz, LOOP
    DONE:
        ENDP
    end asm
end sub

' Recibe un bloque del MCU en memoria (un byte por transaccion de reloj).
' Bucle integramente en ASM: camino critico de LOAD / F_READ.
sub fastcall McuRecvBlock(addr as uinteger, size as uinteger)
    asm
        PROC
        LOCAL LOOP, WAIT, DONE
        ; HL = addr (fastcall); pila: [ret][size]
        pop  de
        pop  bc
        push de

        ld   a, b
        or   c
        jr   z, DONE
    LOOP:
        in   a, ($AF)
        ld   e, a           ; reloj previo
        in   a, ($A7)       ; lee dato
        ld   (hl), a
    WAIT:
        in   a, ($AF)
        xor  e
        jp   p, WAIT
        inc  hl
        dec  bc
        ld   a, b
        or   c
        jr   nz, LOOP
    DONE:
        ENDP
    end asm
end sub

' ======================================================================
' CONVERSION ASCII <-> CODIGOS DE CARACTER ZX81
' ======================================================================

' ASCII -> codigo ZX81. Caracteres sin equivalente -> '?' ($0F).
function _McuToZx(c as ubyte) as ubyte
    if c >= 97 and c <= 122 then
        c = c - 32                      ' minusculas a mayusculas
    end if
    if c >= 65 and c <= 90 then
        return 38 + (c - 65)            ' A-Z
    end if
    if c >= 48 and c <= 57 then
        return 28 + (c - 48)            ' 0-9
    end if
    if c = 32 then return 0             ' espacio
    if c = 34 then return 11            ' "
    if c = 36 then return 13            ' $
    if c = 58 then return 14            ' :
    if c = 63 then return 15            ' ?
    if c = 40 then return 16            ' (
    if c = 41 then return 17            ' )
    if c = 62 then return 18            ' >
    if c = 60 then return 19            ' <
    if c = 61 then return 20            ' =
    if c = 43 then return 21            ' +
    if c = 45 then return 22            ' -
    if c = 42 then return 23            ' *
    if c = 47 then return 24            ' /
    if c = 59 then return 25            ' ;
    if c = 44 then return 26            ' ,
    if c = 46 then return 27            ' .
    return 15                           ' resto: '?'
end function

' Codigo ZX81 -> ASCII (ignora el bit 7 de video inverso).
function _McuFromZx(z as ubyte) as ubyte
    z = z band 127
    if z >= 38 and z <= 63 then
        return 65 + (z - 38)            ' A-Z
    end if
    if z >= 28 and z <= 37 then
        return 48 + (z - 28)            ' 0-9
    end if
    if z = 0  then return 32            ' espacio
    if z = 11 then return 34            ' "
    if z = 13 then return 36            ' $
    if z = 14 then return 58            ' :
    if z = 15 then return 63            ' ?
    if z = 16 then return 40            ' (
    if z = 17 then return 41            ' )
    if z = 18 then return 62            ' >
    if z = 19 then return 60            ' <
    if z = 20 then return 61            ' =
    if z = 21 then return 43            ' +
    if z = 22 then return 45            ' -
    if z = 23 then return 42            ' *
    if z = 24 then return 47            ' /
    if z = 25 then return 59            ' ;
    if z = 26 then return 44            ' ,
    if z = 27 then return 46            ' .
    return 63                           ' resto: '?'
end function

' Convierte una cadena ASCII completa a codigos ZX81.
function McuZxStr(s as string) as string
    dim i as uinteger
    dim r as string
    r = ""
    for i = 0 to len(s) - 1
        r = r + chr(_McuToZx(code(s(i))))
    next i
    return r
end function

' ======================================================================
' PATRONES GENERICOS
' ======================================================================

' Envia una cadena Pascal (longitud + bytes crudos, max 255).
sub _McuSendPascal(dat as string)
    dim addr as uinteger
    dim l as uinteger
    addr = peek(uinteger, @dat)
    l = peek(uinteger, addr)
    if l > 255 then l = 255
    McuSend(cast(ubyte, l))
    if l > 0 then
        McuSendBlock(addr + 2, l)
    end if
end sub

' Comando sin parametros ni respuesta.
sub McuCmd(cmd as ubyte)
    McuSend(cmd)
end sub

' Comando + cadena en crudo + status.
function McuCmdStr(cmd as ubyte, dat as string) as ubyte
    McuSend(cmd)
    _McuSendPascal(dat)
    return McuRecv()
end function

' Comando + cadena (convertida a ZX81) + status. Para comandos de
' fichero/texto (CD, DEL, LOAD, SAY...).
function McuCmdStrZx(cmd as ubyte, dat as string) as ubyte
    return McuCmdStr(cmd, McuZxStr(dat))
end function

' Recibe un stream de caracteres (protocolo NEXTCH $0D hasta EOT $6F)
' y lo devuelve como string ASCII. $76 (newline ZX81) -> CHR(13).
' Deja el status en McuStatus. Para respuestas cortas (PWD, RTC...).
function _McuRecvStream() as string
    dim c as ubyte
    dim r as string
    r = ""
    do
        McuSend($0D)                    ' CMD_NEXTCH: pide un caracter
        c = McuRecv()
        if c = $6F then                 ' EOT
            exit do
        end if
        if c = $76 then
            r = r + chr(13)             ' nueva linea ZX81
        else
            r = r + chr(_McuFromZx(c))
        end if
    loop
    McuStatus = McuRecv()               ' byte de estado final
    return r
end function

' Recibe un stream y lo imprime linea a linea (para listados largos:
' DIR, TYPE, FREE_TXT). Devuelve el status.
function _McuStreamPrint(newLine as ubyte) as ubyte
    dim c as ubyte
    dim line as string
    line = ""
    do
        McuSend($0D)
        c = McuRecv()
        if c = $6F then
            exit do
        end if
        if c = $76 then
			' print
			print line;
			if len(line) <> 32 then print
            line = ""
        else
            line = line + chr(_McuFromZx(c))
			'print c; " ";
        end if
    loop
    if len(line) > 0 then
		if newLine=1 then
			print line
		else
			print line;
		end if
    end if
    return McuRecv()
end function

' ======================================================================
' COMANDOS DE SISTEMA
' ======================================================================

' Cmd 0: sin operacion (sincroniza el reloj).
sub McuNop()
    McuCmd(0)
end sub

' Cmd 1: version del firmware del MCU.
function McuVersion() as ubyte
    McuSend(1)
    return McuRecv()
end function

' Cmd 32: lee un byte de la memoria interna del MCU.
' Indices 0-127: variables volatiles. 128-255: EEPROM (persistente).
function McuGetByte(index as ubyte) as ubyte
    McuSend(32)
    McuSend(index)
    return McuRecv()
end function

' Cmd 33: escribe un byte en la memoria interna del MCU.
sub McuSetByte(index as ubyte, value as ubyte)
    McuSend(33)
    McuSend(index)
    McuSend(value)
end sub

' ======================================================================
' COMANDOS DE SISTEMA DE ARCHIVOS
' ======================================================================

' Cmd 2: directorio actual. Status en McuStatus.
function McuPwd() as string
    McuSend(2)
    return _McuRecvStream()
end function

' Cmd 3: cambia de directorio (rutas absolutas con / o relativas).
function McuCd(path as string) as ubyte
    return McuCmdStrZx(3, path)
end function

' Cmd 4: borra un archivo del directorio actual.
function McuDel(fname as string) as ubyte
    return McuCmdStrZx(4, fname)
end function

' Cmd 5: crea un subdirectorio.
function McuMkdir(dname as string) as ubyte
    return McuCmdStrZx(5, dname)
end function

' Cmd 6: elimina un directorio vacio.
function McuRmdir(dname as string) as ubyte
    return McuCmdStrZx(6, dname)
end function

' Cmd 7/8: renombra-mueve / copia un archivo (dos cadenas seguidas).
function _McuTwoStr(cmd as ubyte, src as string, dst as string) as ubyte
    McuSend(cmd)
    _McuSendPascal(McuZxStr(src))
    _McuSendPascal(McuZxStr(dst))
    return McuRecv()
end function

function McuMove(src as string, dst as string) as ubyte
    return _McuTwoStr(7, src, dst)
end function

function McuCopy(src as string, dst as string) as ubyte
    return _McuTwoStr(8, src, dst)
end function

' Cmd 9: carga un archivo de la SD en memoria a partir de addr.
' Devuelve el numero de bytes cargados (0 si error); status en McuStatus.
' Ojo: extensiones especiales — .ROM resetea la CPU (no retorna),
' .WAV se reproduce (devuelve 0 bytes).
function McuLoad(fname as string, addr as uinteger) as uinteger
    dim lo as ubyte
    dim hi as ubyte
    dim size as uinteger

    McuSend(9)
    _McuSendPascal(McuZxStr(fname))
    lo = McuRecv()
    hi = McuRecv()
    size = cast(uinteger, hi) * 256 + lo
    if size > 0 then
        McuRecvBlock(addr, size)
    end if
    McuStatus = McuRecv()
    return size
end function

' Cmd 10: guarda un bloque de memoria como archivo en la SD.
function McuSave(fname as string, addr as uinteger, size as uinteger) as ubyte
    McuSend(10)
    _McuSendPascal(McuZxStr(fname))
    McuSend(cast(ubyte, size band 255))
    McuSend(cast(ubyte, size >> 8))
    if size > 0 then
        McuSendBlock(addr, size)
    end if
    return McuRecv()
end function

' Cmd 11: imprime el contenido de un archivo de texto.
' Si el nombre empieza por '*' busca en /MAN/ con extension .TXT.
function McuTypePrint(fname as string) as ubyte
    McuSend(11)
    _McuSendPascal(McuZxStr(fname))
    return _McuStreamPrint(1)
end function

' Cmd 12: imprime el listado de un directorio (admite comodines).
function McuDirPrint(mask as string) as ubyte
    McuSend(12)
    _McuSendPascal(McuZxStr(mask))
    return _McuStreamPrint(0)
end function

' Cmd 14: imprime el espacio total/libre de la SD como texto.
function McuFreeTxtPrint() as ubyte
    McuSend(14)
    return _McuStreamPrint(1)
end function

' Cmd 15: espacio total y libre en KB -> McuFreeTotalKb / McuFreeFreeKb.
' Devuelve el status.
function McuFree() as ubyte
    dim i as ubyte
    dim v as ulong

    McuSend(15)
    v = 0
    for i = 0 to 3
        v = v bor (cast(ulong, McuRecv()) << (i * 8))
    next i
    McuFreeTotalKb = v
    v = 0
    for i = 0 to 3
        v = v bor (cast(ulong, McuRecv()) << (i * 8))
    next i
    McuFreeFreeKb = v
    return McuRecv()
end function

' Cmds 16/17/18: OPENDIR / GETROWLEN / GETROW — navegador de directorio.
' ATENCION: no emulados por EightyOne a fecha de hoy (solo HW real);
' en el emulador se quedarian esperando la respuesta.
function McuOpenDir(mask as string) as ubyte
    return McuCmdStrZx(16, mask)
end function

' Devuelve la longitud del nombre de la entrada index; status en McuStatus.
function McuGetRowLen(index as uinteger) as ubyte
    dim l as ubyte
    McuSend(17)
    McuSend(cast(ubyte, index band 255))
    McuSend(cast(ubyte, index >> 8))
    l = McuRecv()
    McuStatus = McuRecv()
    return l
end function

' Devuelve el nombre de la entrada index (0 = directorio actual);
' los directorios van entre < y >. Status en McuStatus.
function McuGetRow(index as uinteger) as string
    dim l as ubyte
    dim i as ubyte
    dim r as string
    McuSend(18)
    McuSend(cast(ubyte, index band 255))
    McuSend(cast(ubyte, index >> 8))
    l = McuRecv()
    r = ""
    if l > 0 then
        for i = 1 to l
            r = r + chr(_McuFromZx(McuRecv()))
        next i
    end if
    McuStatus = McuRecv()
    return r
end function

' ======================================================================
' ACCESO A FICHEROS GRANDES (handles 0-3, tamano 32 bits)
' ======================================================================

' Cmd 53: abre un fichero EXISTENTE para acceso aleatorio. El MCU asigna
' el primer handle libre y lo devuelve (0-3, o $FF si error/no existe).
' El nombre viaja en ASCII crudo (sin conversion; es el fopen de CP/M).
function McuFOpen(fname as string) as ubyte
    McuSend(53)
    _McuSendPascal(fname)               ' ASCII directo, sin conversion
    return McuRecv()
end function

' Cmd 58: igual que McuFOpen pero el nombre viaja en codigos ZX81
' (la conversion desde ASCII la hace esta funcion).
function McuFOpenZx(fname as string) as ubyte
    McuSend(58)
    _McuSendPascal(McuZxStr(fname))
    return McuRecv()
end function

' Cmd 54: situa el puntero de lectura/escritura (offset 32 bits LE).
function McuFSeek(handle as ubyte, offset as ulong) as ubyte
    dim i as ubyte
    McuSend(54)
    McuSend(handle)
    for i = 0 to 3
        McuSend(cast(ubyte, (offset >> (i * 8)) band 255))
    next i
    return McuRecv()
end function

' Cmd 55: lee count bytes al buffer addr. Si el fichero se acaba,
' rellena con ceros (status 1 = lectura corta/EOF).
function McuFRead(handle as ubyte, addr as uinteger, count as uinteger) as ubyte
    McuSend(55)
    McuSend(handle)
    McuSend(cast(ubyte, count band 255))
    McuSend(cast(ubyte, count >> 8))
    if count > 0 then
        McuRecvBlock(addr, count)
    end if
    return McuRecv()
end function

' Cmd 56: escribe count bytes desde addr.
function McuFWrite(handle as ubyte, addr as uinteger, count as uinteger) as ubyte
    McuSend(56)
    McuSend(handle)
    McuSend(cast(ubyte, count band 255))
    McuSend(cast(ubyte, count >> 8))
    if count > 0 then
        McuSendBlock(addr, count)
    end if
    return McuRecv()
end function

' Cmd 57: cierra el fichero.
function McuFClose(handle as ubyte) as ubyte
    McuSend(57)
    McuSend(handle)
    return McuRecv()
end function

' ======================================================================
' CONTROL DEL HARDWARE
' ======================================================================
' ATENCION: los cambios de paginacion/RAM pueden dejar sin sentido el
' mapa de memoria del programa en ejecucion. Usar solo sabiendo lo que
' se hace.

' Mapeador de memoria del SD81 (puerto $E7, directo a la FPGA — no pasa
' por el MCU). Equivale al LOAD *MAP bloque,pagina del BASIC.
'
' El espacio de 64K se divide en 8 bloques de 8K (bloque 0 = $0000-$1FFF
' ... bloque 7 = $E000-$FFFF); cada bloque puede apuntar a cualquier
' pagina fisica de 8K de la RAM de 512K (0-31 en paginacion simple,
' 0-63 en paginacion completa — ver McuFullPaging/McuHalfPaging).
'
' La escritura vale para AMBOS modos: pone la pagina en B (A8-A13, que
' es de donde la lee el modo completo) Y en los bits 7-3 del dato (de
' donde la lee el modo simple).
'
' CUIDADO: remapear un bloque donde vive el propio programa, las
' sysvars ($8000, bloque 4) o la pantalla ($C000, bloque 6) cuelga o
' corrompe el sistema.
sub fastcall Map(block as ubyte, page as ubyte)
    asm
        ; A = block (fastcall); pila: [ret][page en byte alto]
        pop  hl             ; direccion de retorno
        pop  de             ; D = page
        push hl
        and  7
        ld   l, a           ; L = bloque (0-7)
        ld   b, d           ; B = pagina completa (aparece en A8-A15)
        ld   c, $E7
        ld   a, d
        and  31
        rlca
        rlca
        rlca                ; (pagina AND 31) << 3
        or   l              ; dato = pagina<<3 | bloque (modo simple)
        out  (c), a         ; una sola escritura vale para ambos modos
    end asm
end sub

' Lee la pagina actualmente asignada a un bloque (lectura de $E7 con
' el bloque en A10-A8).
function fastcall MapGet(block as ubyte) as ubyte
    asm
        ; A = block (fastcall)
        and  7
        ld   b, a           ; B aparece en A8-A15 durante IN A,(C)
        ld   c, $E7
        in   a, (c)         ; A = pagina asignada (resultado fastcall)
    end asm
end function

sub McuEnableMc45()
    McuCmd(19)
end sub

sub McuDisableMc45()
    McuCmd(20)
end sub

sub McuSel128Chars()
    McuCmd(27)
end sub

sub McuSel64Chars()
    McuCmd(28)
end sub

sub McuFullPaging()
    McuCmd(29)
end sub

sub McuHalfPaging()
    McuCmd(30)
end sub

sub McuRam48On()
    McuCmd(48)
end sub

sub McuRam48Off()
    McuCmd(49)
end sub

' ======================================================================
' SINTESIS DE VOZ
' ======================================================================

' Cmd 23: convierte texto a fonemas y lo reproduce.
' Si el primer caracter es '*', reproduce en background.
function McuSay(text as string) as ubyte
    return McuCmdStrZx(23, text)
end function

' Cmd 22: reproduce alofonos SP0256-AL2 en crudo (codigos $00-$3F).
' Sincrono: bloquea hasta terminar.
function McuBinarySay(allophones as string) as ubyte
    return McuCmdStr(22, allophones)
end function

' ======================================================================
' AY POR MCU (chip 2: el AY "B" del SD81) Y PLAY EN BACKGROUND
' ======================================================================

' Cmd 24: escribe un registro del AY del MCU (chip 2). Sin status.
sub McuAySetReg(reg as ubyte, value as ubyte)
    McuSend(24)
    McuSend(reg)
    McuSend(value)
end sub

' Cmd 25: lee un registro del AY del MCU (chip 2).
function McuAyGetReg(reg as ubyte) as ubyte
    McuSend(25)
    McuSend(reg)
    return McuRecv()
end function

' Convierte una cadena MML de PLAY conservando la semantica de octavas
' del interprete del MCU: minuscula ASCII -> letra ZX81 normal
' (octava base - 1), MAYUSCULA ASCII -> letra ZX81 en video inverso
' (octava base). Igual que el PLAY local de play.bas.
function _McuPlayStr(s as string) as string
    dim i as uinteger
    dim c as ubyte
    dim r as string
    r = ""
    for i = 0 to len(s) - 1
        c = code(s(i))
        if c >= 65 and c <= 90 then
            r = r + chr(128 + 38 + (c - 65))    ' mayuscula: inverso
        else
            r = r + chr(_McuToZx(c))
        end if
    next i
    return r
end function

' Cmd 26: PLAY de hasta 3 canales en el AY del MCU (chip 2).
' Si el canal A empieza por '*', reproduce en background.
function McuAyPlay(chanA as string, chanB as string, chanC as string) as ubyte
    McuSend(26)
    _McuSendPascal(_McuPlayStr(chanA))
    _McuSendPascal(_McuPlayStr(chanB))
    _McuSendPascal(_McuPlayStr(chanC))
    return McuRecv()
end function

' ======================================================================
' REPRODUCTOR VGM
' ======================================================================

' Cmd 34: abre un archivo VGM (anade .vgm si no tiene extension) y lo
' prepara; iniciar con McuContVgm().
function McuPlayVgm(fname as string) as ubyte
    return McuCmdStrZx(34, fname)
end function

sub McuStopVgm()
    McuCmd(35)
end sub

sub McuPauseVgm()
    McuCmd(36)
end sub

sub McuContVgm()
    McuCmd(37)
end sub

' Cmd 38: modo de bucle (0 = no, 1 = si). Sin status.
sub McuLoopVgm(mode as ubyte)
    McuSend(38)
    McuSend(mode)
end sub

' ======================================================================
' PEG (Programmable Effects Generator)
' ======================================================================

' Cmd 40: carga instrucciones en la memoria PEG a partir de address.
' dat contiene los bytes crudos (2 bytes little-endian por instruccion).
' Sin status.
sub McuLoadPeg(address as ubyte, dat as string)
    McuSend(40)
    McuSend(address)
    _McuSendPascal(dat)
end sub

' Cmd 41: arranca un hilo PEG (0-2) en la direccion dada. Sin status.
sub McuPlayPeg(thread as ubyte, address as ubyte)
    McuSend(41)
    McuSend(thread)
    McuSend(address)
end sub

sub McuStopPeg(thread as ubyte)
    McuSend(42)
    McuSend(thread)
end sub

sub McuPausePeg(thread as ubyte)
    McuSend(43)
    McuSend(thread)
end sub

sub McuContPeg(thread as ubyte)
    McuSend(44)
    McuSend(thread)
end sub

' Cmd 45: carga un archivo .PEB de la SD en la memoria PEG (max 512B).
function McuSdLoadPeg(fname as string, address as ubyte) as ubyte
    McuSend(45)
    _McuSendPascal(McuZxStr(fname))
    McuSend(address)
    return McuRecv()
end function

' ======================================================================
' RTC Y BATERIA
' ======================================================================

' Cmd 50 (lectura): devuelve "AAAA-MM-DD HH:MM:SS.CC" (22 caracteres).
' Status en McuStatus.
function McuRtc() as string
    dim i as ubyte
    dim r as string
    McuSend(50)
    McuSend(0)                          ' cadena vacia = lectura
    r = ""
    for i = 1 to 22
        r = r + chr(_McuFromZx(McuRecv()))
    next i
    McuStatus = McuRecv()
    return r
end function

' Cmd 50 (escritura): ajusta el reloj. Formatos: "AAAA-MM-DD HH:MM:SS",
' "AAAA-MM-DD", "HH:MM:SS", "HH:MM", etc.
function McuRtcSet(datetime as string) as ubyte
    return McuCmdStrZx(50, datetime)
end function

' Cmd 52: nivel de bateria del RTC como texto "V.mmm" (5 caracteres).
' Status en McuStatus.
function McuBat() as string
    dim i as ubyte
    dim r as string
    McuSend(52)
    r = ""
    for i = 1 to 5
        r = r + chr(_McuFromZx(McuRecv()))
    next i
    McuStatus = McuRecv()
    return r
end function

' ======================================================================
' UTILIDADES (equivalentes de las extensiones BASIC del SD81)
' ======================================================================
' Para *LDIR/*LDDR usar MemMove de <memcopy.bas> (stdlib estandar), que
' ademas elige el sentido de copia correcto cuando hay solapamiento.
' Para *OUT/*IN y los PEEK/POKE de 16 bits, zxbasic ya tiene OUT, IN(),
' peek(uinteger, ...) y poke uinteger nativos.

' Valor de un digito hexadecimal ASCII, o 255 si no lo es.
function _HexDigit(c as ubyte) as ubyte
    if c >= 48 and c <= 57 then
        return c - 48                   ' 0-9
    end if
    if c >= 65 and c <= 70 then
        return c - 55                   ' A-F
    end if
    if c >= 97 and c <= 102 then
        return c - 87                   ' a-f
    end if
    return 255
end function

' Equivalente de LOAD *HEX: vuelca una cadena hexadecimal en memoria
' ("0A014020" -> bytes $0A,$01,$40,$20 a partir de addr).
' Devuelve el numero de bytes escritos (se detiene en el primer
' caracter no hexadecimal o si la cadena tiene longitud impar).
function HexPoke(addr as uinteger, hx as string) as uinteger
    dim i as uinteger
    dim n as uinteger
    dim hi as ubyte
    dim lo as ubyte

    n = 0
    i = 0
    do while i + 2 <= len(hx)
        hi = _HexDigit(code(hx(i)))
        lo = _HexDigit(code(hx(i + 1)))
        if hi = 255 or lo = 255 then
            exit do
        end if
        poke addr + n, (hi << 4) bor lo
        n = n + 1
        i = i + 2
    loop
    return n
end function

' Equivalente de LOAD *INV: invierte el bit 7 de todos los caracteres.
' Nota: en zxbasic el video inverso al imprimir se hace con PRINT
' INVERSE; esto sirve para preparar buffers en codificacion ZX81
' (p.ej. cadenas para McuAyPlay o para escribir en pantalla nativa).
function StrInv(s as string) as string
    dim i as uinteger
    dim r as string
    r = ""
    for i = 0 to len(s) - 1
        r = r + chr(code(s(i)) bxor 128)
    next i
    return r
end function

' Equivalente de LOAD *BOLD: fuerza a 1 el bit 7 de todos los caracteres.
function StrBold(s as string) as string
    dim i as uinteger
    dim r as string
    r = ""
    for i = 0 to len(s) - 1
        r = r + chr(code(s(i)) bor 128)
    next i
    return r
end function

#pragma pop(explicit)
