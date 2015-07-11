;The MIT License
;
;Copyright (c) 2008 Dylan Smith
;
;Permission is hereby granted, free of charge, to any person obtaining a copy
;of this software and associated documentation files (the "Software"), to deal
;in the Software without restriction, including without limitation the rights
;to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
;copies of the Software, and to permit persons to whom the Software is
;furnished to do so, subject to the following conditions:
;
;The above copyright notice and this permission notice shall be included in
;all copies or substantial portions of the Software.
;
;THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
;THE SOFTWARE.

; This file can be included in assembly language programs to give
; symbolic access to the public jump table entry points.

; Avoid double inclusion
#ifndef __SPECTRANET_INC__
#define __SPECTRANET_INC__

NAMESPACE Spectranet  ; NAME PREFIX to avoid naming clash

; Hardware page-in entry points
MODULECALL      equ $3FF8
MODULECALL_NOPAGE       equ $28
PAGEIN          equ $3FF9
PAGEOUT         equ $007C
HLCALL          equ $3FFA
IXCALL          equ $3FFD

; Port defines
CTRLREG         equ $033B
CPLDINFO        equ $023B

; Jump table entry points
SOCKET          equ $3E00      ; Allocate a socket
CLOSE           equ $3E03      ; Close a socket
LISTEN          equ $3E06      ; Listen for incoming connections
ACCEPT          equ $3E09      ; Accept an incoming connection
BIND            equ $3E0C      ; Bind a local address to a socket
CONNECT         equ $3E0F      ; Connect to a remote host
SEND            equ $3E12      ; Send data 
RECV            equ $3E15      ; Receive data 
SENDTO          equ $3E18      ; Send data to an address
RECVFROM        equ $3E1B      ; Receive data from an address
POLL            equ $3E1E      ; Poll a list of sockets
POLLALL         equ $3E21      ; Poll all open sockets
POLLFD          equ $3E24      ; Poll a single socket
GETHOSTBYNAME   equ $3E27      ; Look up a hostname
PUTCHAR42       equ $3E2A      ; 42 column print write a character
PRINT42         equ $3E2D      ; 42 column print a null terminated string
CLEAR42         equ $3E30      ; Clear the screen and reset 42-col print
SETPAGEA        equ $3E33      ; Sets page area A
SETPAGEB        equ $3E36      ; Sets page area B
LONG2IPSTRING   equ $3E39      ; Convert a 4 byte big endian long to an IP
IPSTRING2LONG   equ $3E3C      ; Convert an IP to a 4 byte big endian long
ITOA8           equ $3E3F      ; Convert a byte to ascii
RAND16          equ $3E42      ; 16 bit PRNG
REMOTEADDRESS   equ $3E45      ; Fill struct sockaddr_in
IFCONFIG_INET   equ $3E48      ; Set IPv4 address
IFCONFIG_NETMASK equ $3E4B     ; Set netmask
IFCONFIG_GW     equ $3E4E      ; Set gateway
INITHW          equ $3E51      ; Set the MAC address and initial hw registers
GETHWADDR       equ $3E54      ; Read the MAC address
DECONFIG        equ $3E57      ; Deconfigure inet, netmask and gateway
MAC2STRING      equ $3E5A      ; Convert 6 byte MAC address to a string
STRING2MAC      equ $3E5D      ; Convert a hex string to a 6 byte MAC address
ITOH8           equ $3E60      ; Convert accumulator to hex string
HTOI8           equ $3E63      ; Convert hex string to byte in A
GETKEY          equ $3E66      ; Get a key from the keyboard, and put it in A
KEYUP           equ $3E69      ; Wait for key release
INPUTSTRING     equ $3E6C      ; Read a string into buffer at DE
GET_IFCONFIG_INET equ $3E6F    ; Gets the current IPv4 address
GET_IFCONFIG_NETMASK equ $3E72 ; Gets the current netmask
GET_IFCONFIG_GW equ $3E75      ; Gets the current gateway address
SETTRAP         equ $3E78      ; Sets the programmable trap
DISABLETRAP     equ $3E7B      ; Disables the programmable trap
ENABLETRAP      equ $3E7E      ; Enables the programmable trap
PUSHPAGEA       equ $3E81      ; Pages a page into area A, pushing the old one
POPPAGEA        equ $3E84      ; Restores the previous page in area A
PUSHPAGEB       equ $3E87      ; Pages into area B pushing the old one
POPPAGEB        equ $3E8A      ; Restores the previous page in area B
PAGETRAPRETURN  equ $3E8D      ; Returns from a trap to page area B
TRAPRETURN      equ $3E90      ; Returns from a trap that didn't page area B
ADDBASICEXT     equ $3E93      ; Adds a BASIC command
STATEMENT_END   equ $3E96      ; Check for statement end, exit at syntax time
EXIT_SUCCESS    equ $3E99      ; Use this to exit successfully after cmd
PARSE_ERROR     equ $3E9C      ; Use this to exit to BASIC with a parse error
RESERVEPAGE     equ $3E9F      ; Reserve a page of static RAM
FREEPAGE        equ $3EA2      ; Free a page of static RAM
REPORTERR       equ $3EA5      ; report an error via BASIC

; Filesystem functions
MOUNT           equ $3EA8
UMOUNT          equ $3EAB
OPENDIR         equ $3EAE
OPEN            equ $3EB1
UNLINK          equ $3EB4
MKDIR           equ $3EB7
RMDIR           equ $3EBA
SIZE            equ $3EBD
FREE            equ $3EC0
STAT            equ $3EC3
CHMOD           equ $3EC6
READ            equ $3EC9
WRITE           equ $3ECC
LSEEK           equ $3ECF
VCLOSE          equ $3ED2
VPOLL           equ $3ED5
READDIR         equ $3ED8
CLOSEDIR        equ $3EDB
CHDIR           equ $3EDE
GETCWD          equ $3EE1
RENAME          equ $3EE4
SETMOUNTPOINT   equ $3EE7
FREEMOUNTPOINT  equ $3EEA
RESALLOC        equ $3EED


; Definitions
ALLOCFD         equ 1
FREEFD          equ 0
ALLOCDIRHND     equ 3
FREEDIRHND      equ 2

; POLL status bits
BIT_RECV        equ 2
BIT_DISCON      equ 1
BIT_CONN        equ 0

NAMESPACE DEFAULT           ; Clears namespace

#endif

