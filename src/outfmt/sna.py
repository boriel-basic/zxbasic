#!/usr/bin/env python3

# 48K .SNA format output module
#
# © Copyright 2008-2024 José Manuel Rodríguez de la Rosa and contributors.
# See the file AUTHORS for copyright details.
#
# This file is part of Boriel BASIC Compiler.
#
# Boriel BASIC Compiler is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option) any
# later version.
#
# Boriel BASIC Compiler is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along with
# Boriel BASIC Compiler. If not, see <https://www.gnu.org/licenses/>.


from .codeemitter import CodeEmitter


class SnaEmitter(CodeEmitter):
    """Class to emit 48K .SNA snapshots"""

    # Utility functions
    @staticmethod
    def word(x: int):
        """Convert an integer to an iterable of 2 little-endian bytes"""
        return bytes((x % 256, x >> 8))

    def patchAddr(self, addr: int, data: bytes):
        """Patch the snapshot at the given address"""
        self.patchIdx(addr + (0x1B - 16384), data)

    def patchIdx(self, idx: int, data: bytes):
        """Patch the snapshot at the given array index"""
        self.output[idx : idx + len(data)] = data
        assert len(self.output) == 49179

    def __init__(self):
        """Initializes the base .SNA bytes"""

        """
        Format of SNA file:

        $00  I
        $01  HL'
        $03  DE'
        $05  BC'
        $07  AF'
        $09  HL
        $0B  DE
        $0D  BC
        $0F  IY
        $11  IX
        $13  IFF2    [Only bit 2 is defined: 1 for EI, 0 for DI]
        $14  R
        $15  AF
        $17  SP
        $19  Interrupt mode: 0, 1 or 2
        $1A  Border colour

        PC is on the stack. A `retn` instruction should be executed after load.
        """

        # Start with an array of 49179 zeros, then patch the different areas
        self.output = bytearray(b'\0' * 49179)

        # Registers in header
        self.patchIdx(0,
            b'\x3F'             # I
            b'\0\0\0\0\0\0\0\0' # HL', DE', BC', AF'
            b'\0\0\0\0\0\0'     # HL, DE, BC
            b'\x3A\x5C'         # IY
            b'\0\0'             # IX
            b'\x04'             # Interrupts enabled
            b'\0'               # R
            b'\0\0'             # AF
            b'\0\0'             # SP (to be patched with clear addr - 5)
            b'\1\7'             # IM1, Border 7
        )

        # Screen Attributes
        self.patchAddr(0x5800, b'\x38' * 768)

        # System Variables
        # The author knows very little about KSTATE, so just in case, the
        # eight state bytes have been copied from an actual snapshot.
        self.patchAddr(0x5C00,
            b'\xFF\0\0\0\x0D\2\x20\x0D'  # KSTATE
            b'\x0D'              # LAST_K
            b'\x23'              # REPDEL
            b'\x05'              # REPPER
            b'\0\0\0\0\0'        # DEFADD, K_DATA, TVDATA
            b'\1\0\6\0\x0B\0\1\0\1\0\6\0\x10\0'
            b'\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0'
            b'\0\0\0\0\0\0\0\0'  # STRMS (38 bytes total)
            b'\x00\x3C'          # CHARS
            b'\x40\x00'          # RASP, PIP
            b'\xFF'              # ERR_NR
            b'\xCC'              # FLAGS
            b'\x01'              # TV_FLAG
            b'\0\0'              # ERR_SP (to be patched with clear addr - 3)
            b'\0\0'              # LIST_SP (overwritten by ROM)
            b'\0'                # MODE
            b'\0\0\0'            # NEWPPC, NSPPC (at start of BASIC)
            b'\xFE\xFF\1'        # PPC, SUBPPC (at line -2, edit line)
            b'\x38'              # BORDCR
            b'\0\0'              # E_PPC
            b'\0\0'              # VARS (patched later, depends on prog length)
            b'\0\0'              # DEST
            b'\xB6\x5C'          # CHANS
            b'\xB6\x5C'          # CURCHL
            b'\xCB\x5C'          # PROG
            b'\0\0'              # NXTLIN (overwritten by ROM)
            b'\xCA\x5C'          # DATADD
            b'\0\0'              # E_LINE (patched later)
            b'\0\0'              # K_CUR (overwritten by ROM)
            b'\0\0'              # CH_ADD (overwritten by ROM)
            b'\0\0'              # X_PTR
            b'\0\0'              # WORKSP (patched later)
            b'\0\0'              # STKBOT (patched later)
            b'\0\0'              # STKEND (patched later)
            b'\0'                # BREG
            b'\x92\x5C'          # MEM
            b'\x10'              # FLAGS2
            b'\2'                # DF_SZ
            b'\0\0\0\0\0'        # S_TOP, OLDPPC, OSPPC
            b'\0\0\0'            # FLAGX, STRLEN
            b'\0\0'              # T_ADDR (overwritten by ROM)
            b'\0\0'              # SEED
            b'\0\0\0'            # FRAMES
            b'\x58\xFF'          # UDG
            b'\0\0'              # COORDS
            b'\x21'              # P_POSN
            b'\0\x5B'            # PR_CC
            b'\x21\x17'          # ECHO_E
            b'\0\x40'            # DF_CC
            b'\xE0\x50'          # DFCCL
            b'\x21\x18'          # S_POSN
            b'\x21\x17'          # SPOSNL
            b'\1'                # SCR_CT
            b'\x38\x00\x38\x00'  # ATTR_P, MASK_P, ATTR_T, MASK_T
            b'\0'                # P_FLAG
            b'\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0'
            b'\0\0\0\0\0\0\0\0'  # MEMBOT (30 bytes)
            b'\0\0'              # NMIADD
            b'\0\0'              # RAMTOP (patched later)
            b'\xFF\xFF'          # P_RAMT
        )

        ChansData = (
            # CHANS data (routine pointers, channel name)
            b'\xF4\x09\xA8\x10' b'K'  # PRINT_OUT, KEY_INPUT, "K"
            b'\xF4\x09\xC4\x15' b'S'  # PRINT_OUT, REPORT_J, "S"
            b'\x81\x0F\xC4\x15' b'R'  # ADD_CHAR, REPORT_J, "R"
            b'\xF4\x09\xC4\x15' b'P'  # PRINT_OUT, REPORT_J, "P"
            b'\x80'                   # Terminator
        )

        # CHANS data starts at 23734 and could vary in length depending on
        # the presence of an Interface 1.
        self.patchAddr(23734, ChansData)

        # BASIC start (usually 23755 in absence of Interface 1)
        self.BasicStart = 23734 + len(ChansData)


    def emit(
        self,
        output_filename,
        program_name,
        loader_bytes,
        entry_point,
        program_bytes,
        aux_bin_blocks,
        aux_headless_bin_blocks,
    ):
        """Emit a .SNA file with the compiled bytes; ignores loader_bytes"""

        # Clear address could be different from entry_point-1 in future.
        clear_addr = entry_point - 1

        # Ignore loader_bytes and use our own BASIC program
        loader_bytes = bytearray(
            b'\0\x0A'          # BASIC big endian line num
            b'\x0F\0'          # BASIC little endian line length
            b'\xFA\xC0'        # BASIC IF USR
        )
        loader_bytes.extend(b'%05d\x0E\0\0\0\0\0' % entry_point)
        loader_bytes[-3:-1] = self.word(entry_point)
        loader_bytes.extend(b'\xCB\x0D')  # THEN + final newline
        BasicLength = len(loader_bytes)

        # Address to array index conversion offset; 0x1B is the header size
        BasicEnd = self.BasicStart + BasicLength

        # Clear everything from the channel variables to the UDG start
        self.patchAddr(self.BasicStart, b'\x00' * (65368 - self.BasicStart))

        # Patch SP register in header
        self.patchIdx(0x17, self.word(clear_addr - 5))

        # Patch ERR_SP
        self.patchAddr(23613, self.word(clear_addr - 3))
        # Patch VARS
        self.patchAddr(23627, self.word(BasicEnd))
        # Patch E_LINE
        self.patchAddr(23641, self.word(BasicEnd + 1))
        # Patch WORKSP
        self.patchAddr(23649, self.word(BasicEnd + 4))
        # Patch STKBOT
        self.patchAddr(23651, self.word(BasicEnd + 4))
        # Patch STKEND
        self.patchAddr(23653, self.word(BasicEnd + 4))
        # Patch RAMTOP
        self.patchAddr(23730, self.word(clear_addr))

        # Patch BASIC program
        self.patchAddr(self.BasicStart, loader_bytes)

        # Patch variables, edit line and calculator stack (edit line contains
        # a RUN command, 0xF7; calculator stack is empty)
        self.patchAddr(BasicEnd, b'\x80\xF7\x0D\x80')

        # Patch stack
        self.patchAddr(clear_addr - 5,
            b'\x9E\x1B'  # Entry address: LINE_NEW
            b'\x03\x13'  # Error resume routine (ERR_SP points here): MAIN_4
            b'\x00\x3E'  # GOSUB stack end marker
        )

        # UDG area (might be overwritten by compiled code)
        self.patchAddr(65368,
            b'\x00\x3C\x42\x42\x7E\x42\x42\x00\x00\x7C\x42\x7C\x42\x42\x7C\x00'
            b'\x00\x3C\x42\x40\x40\x42\x3C\x00\x00\x78\x44\x42\x42\x44\x78\x00'
            b'\x00\x7E\x40\x7C\x40\x40\x7E\x00\x00\x7E\x40\x7C\x40\x40\x40\x00'
            b'\x00\x3C\x42\x40\x4E\x42\x3C\x00\x00\x42\x42\x7E\x42\x42\x42\x00'
            b'\x00\x3E\x08\x08\x08\x08\x3E\x00\x00\x02\x02\x02\x42\x42\x3C\x00'
            b'\x00\x44\x48\x70\x48\x44\x42\x00\x00\x40\x40\x40\x40\x40\x7E\x00'
            b'\x00\x42\x66\x5A\x42\x42\x42\x00\x00\x42\x62\x52\x4A\x46\x42\x00'
            b'\x00\x3C\x42\x42\x42\x42\x3C\x00\x00\x7C\x42\x42\x7C\x40\x40\x00'
            b'\x00\x3C\x42\x42\x52\x4A\x3C\x00\x00\x7C\x42\x42\x7C\x44\x42\x00'
            b'\x00\x3C\x40\x3C\x02\x42\x3C\x00\x00\xFE\x10\x10\x10\x10\x10\x00'
            b'\x00\x42\x42\x42\x42\x42\x3C\x00'
        )

        # Patch compiled code in
        assert entry_point + len(program_bytes) <= 65536
        self.patchAddr(entry_point, program_bytes)

        # Write output file
        with open(output_filename, "wb") as f:
            f.write(self.output)
