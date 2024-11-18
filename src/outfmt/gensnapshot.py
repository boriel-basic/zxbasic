# 48K Snapshot generation module
#
# © Copyright 2008-2024 José Manuel Rodríguez de la Rosa and contributors.
# See the file AUTHORS for copyright details.
#
# This file is part of Boriel BASIC Compiler.
#
# Boriel BASIC Compiler is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or (at your
# option) any later version.
#
# Boriel BASIC Compiler is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License
# for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with Boriel BASIC Compiler. If not, see <https://www.gnu.org/licenses/>.


class GenSnapshot:
    """Generate 48K snapshots with the given BASIC and MC code

    If no BASIC is given, it will insert its own BASIC program, consisting of
    a single line that reads:

    10 IF USR <mc_addr> THEN
    """

    # Utility functions
    @staticmethod
    def word(x: int):
        """Convert an integer to an iterable of 2 little-endian bytes"""
        return bytes((x % 256, x >> 8))

    def patchAddr(self, addr: int, data: bytes):
        """Patch the snapshot's memory image at the given address"""
        self.mem[addr - 16384 : addr - 16384 + len(data)] = data
        assert len(self.mem) == 49152

    def __init__(
        self,
        loader_bytes,
        clear_addr,
        mc_addr,
        mc_bytes,
    ):
        """
        Creates a snapshot object ready to run a BASIC program as if RUN was just executed.

        Input:

            loader_bytes: ZX Spectrum BASIC code to inject as the BASIC program.
                If None, a program consisting of this single line will be generated:
                    10 IF USR <mc_addr> THEN
            clear_addr: Address of CLEAR
            mc_addr: Address where the bytes need to be stored
            mc_bytes: Bytes to store starting at mc_addr

        Output: An object with the following fields:

            mem: A bytearray object with the memory dump
            A: the Z80 A register
            B, C, D, E, H, L, F, A2, B2, C2, D2, E2, H2, L2, F2, I, R: same
            W: high byte of the WZ internal register
            Z: low byte of the WZ internal register
            SPH: High byte of SP
            SPL: Low byte of SP
            PCH: High byte of PC
            PCL: Low byte of PC
            IXH: High byte of IX
            IXL: Low byte of IX
            IYH: High byte of IY
            IYL: Low byte of IY
            IFF1: IFF1 flag of Z80 (0 to 1, as int)
            IFF2: IFF2 flag of Z80 (0 to 1, as int)
            outFE: Last byte output to port 0FEh
            IM: Interrupt mode (0 to 2, as int)
            cycles: Cycles after the last interrupt
            halted: Whether we're in a halted state
            eilast: Whether the last instruction prevents an interrupt
        """

        self.A = self.A2 = self.B = self.B2 = self.C = self.C2 = self.D = self.D2 = self.E = self.E2 = self.H = (
            self.H2
        ) = self.L = self.L2 = self.F = self.F2 = self.R = self.IXL = self.IXH = 0

        self.IYH = 0x5C
        self.IYL = 0x3A  # 0x5C3A is the normal value of IY for ROM use
        self.I = 0x3F
        self.W = 0
        self.Z = 0
        self.IFF1 = 1
        self.IFF2 = 1
        self.PCH = 0x1B
        self.PCL = 0x9E  # Entry point: 1B9E, LINE_NEW
        SP = clear_addr - 3
        self.SPH = (SP >> 8) & 0xFF
        self.SPL = SP & 0xFF
        self.IM = 1
        self.outFE = 0x0F  # Border 7, input enabled, speaker disabled
        self.cycles = 35000  # Half a screen, roughly
        self.halted = False
        self.eilast = False

        # Build a valid memory image from scratch
        # Start with an array of 49152 zeros, then patch the different areas
        self.mem = bytearray(b"\0" * 49152)

        # Screen Attributes
        self.patchAddr(0x5800, b"\x38" * 768)  # all Paper 7 / Ink 0

        # System Variables
        # The author knows very little about KSTATE, so just in case, the
        # eight state bytes have been copied from an actual snapshot.
        self.patchAddr(
            0x5C00,
            b"\xff\0\0\0"
            b"\x0d\2\x20\x0d"  # KSTATE
            b"\x0d"  # LAST_K
            b"\x23"  # REPDEL
            b"\x05"  # REPPER
            b"\0\0\0\0\0"  # DEFADD, K_DATA, TVDATA
            b"\1\0\6\0\x0b\0\1\0\1\0\6\0\x10\0"
            b"\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0"
            b"\0\0\0\0\0\0\0\0"  # STRMS (38 bytes total)
            b"\x00\x3c"  # CHARS
            b"\x40\x00"  # RASP, PIP
            b"\xff"  # ERR_NR
            b"\xcc"  # FLAGS
            b"\x00"  # TV_FLAG
            b"\0\0"  # ERR_SP (to be patched with clear addr - 3)
            b"\0\0"  # LIST_SP (overwritten by ROM)
            b"\0"  # MODE
            b"\0\0\0"  # NEWPPC, NSPPC (at start of BASIC)
            b"\xfe\xff\1"  # PPC, SUBPPC (at line -2, edit line)
            b"\x38"  # BORDCR
            b"\0\0"  # E_PPC
            b"\0\0"  # VARS (patched later, depends on prog length)
            b"\0\0"  # DEST
            b"\xb6\x5c"  # CHANS
            b"\xb6\x5c"  # CURCHL
            b"\xcb\x5c"  # PROG
            b"\0\0"  # NXTLIN (overwritten by ROM)
            b"\xca\x5c"  # DATADD
            b"\0\0"  # E_LINE (patched later)
            b"\0\0"  # K_CUR (overwritten by ROM)
            b"\0\0"  # CH_ADD (overwritten by ROM)
            b"\0\0"  # X_PTR
            b"\0\0"  # WORKSP (patched later)
            b"\0\0"  # STKBOT (patched later)
            b"\0\0"  # STKEND (patched later)
            b"\0"  # BREG
            b"\x92\x5c"  # MEM
            b"\x10"  # FLAGS2
            b"\2"  # DF_SZ
            b"\0\0\0\0\0"  # S_TOP, OLDPPC, OSPPC
            b"\0\0\0"  # FLAGX, STRLEN
            b"\0\0"  # T_ADDR (overwritten by ROM)
            b"\0\0"  # SEED
            b"\0\0\0"  # FRAMES
            b"\x58\xff"  # UDG
            b"\0\0"  # COORDS
            b"\x21"  # P_POSN
            b"\0\x5b"  # PR_CC
            b"\x21\x17"  # ECHO_E
            b"\0\x40"  # DF_CC
            b"\xe0\x50"  # DFCCL
            b"\x21\x18"  # S_POSN
            b"\x21\x17"  # SPOSNL
            b"\1"  # SCR_CT
            b"\x38\x00\x38\x00"  # ATTR_P, MASK_P, ATTR_T, MASK_T
            b"\0"  # P_FLAG
            b"\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0"
            b"\0\0\0\0\0\0\0\0"  # MEMBOT (30 bytes)
            b"\0\0"  # NMIADD
            b"\0\0"  # RAMTOP (patched later)
            b"\xff\xff",  # P_RAMT
        )

        ChansData = (
            # CHANS data (routine pointers, channel name)
            b"\xf4\x09\xa8\x10"
            b"K"  # PRINT_OUT, KEY_INPUT, "K"
            b"\xf4\x09\xc4\x15"
            b"S"  # PRINT_OUT, REPORT_J, "S"
            b"\x81\x0f\xc4\x15"
            b"R"  # ADD_CHAR, REPORT_J, "R"
            b"\xf4\x09\xc4\x15"
            b"P"  # PRINT_OUT, REPORT_J, "P"
            b"\x80"  # Terminator
        )

        # CHANS data starts at 23734 and could vary in length depending on
        # the presence of an Interface 1.
        self.patchAddr(23734, ChansData)

        # BASIC start (usually 23755 in absence of Interface 1)
        self.BasicStart = 23734 + len(ChansData)

        if loader_bytes is None:
            # Create a single line with these contents: 10 IF USR <mc_addr> THEN
            loader_bytes = bytearray(
                b"\0\x0a"  # BASIC big endian line num
                b"\0\0"  # BASIC little endian line length (patched below)
                b"\xfa\xc0"  # BASIC IF USR
            )
            loader_bytes.extend(b"%05d\x0e\0\0\0\0\0" % mc_addr)
            loader_bytes[-3:-1] = self.word(mc_addr)
            loader_bytes.extend(b"\xcb\x0d")  # THEN + final newline
            loader_bytes[2:4] = self.word(len(loader_bytes) - 4)  # line length

        BasicLength = len(loader_bytes)

        # Address to array index conversion offset; 0x1B is the header size
        BasicEnd = self.BasicStart + BasicLength

        # Clear everything from the channel variables to the UDG start
        self.patchAddr(self.BasicStart, b"\x00" * (65368 - self.BasicStart))

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

        # Patch variables area, edit line and calculator stack (edit line
        # contains a RUN command, 0xF7; calculator stack is empty)
        self.patchAddr(BasicEnd, b"\x80\xf7\x0d\x80")

        # Patch stack
        self.patchAddr(
            clear_addr - 3,
            b"\x03\x13"  # Error resume routine (ERR_SP points here): MAIN_4
            b"\x00\x3e",  # GOSUB stack end marker
        )

        # UDG area (might be overwritten by compiled code)
        self.patchAddr(
            65368,
            b"\x00\x3c\x42\x42\x7e\x42\x42\x00\x00\x7c\x42\x7c\x42\x42\x7c\x00"
            b"\x00\x3c\x42\x40\x40\x42\x3c\x00\x00\x78\x44\x42\x42\x44\x78\x00"
            b"\x00\x7e\x40\x7c\x40\x40\x7e\x00\x00\x7e\x40\x7c\x40\x40\x40\x00"
            b"\x00\x3c\x42\x40\x4e\x42\x3c\x00\x00\x42\x42\x7e\x42\x42\x42\x00"
            b"\x00\x3e\x08\x08\x08\x08\x3e\x00\x00\x02\x02\x02\x42\x42\x3c\x00"
            b"\x00\x44\x48\x70\x48\x44\x42\x00\x00\x40\x40\x40\x40\x40\x7e\x00"
            b"\x00\x42\x66\x5a\x42\x42\x42\x00\x00\x42\x62\x52\x4a\x46\x42\x00"
            b"\x00\x3c\x42\x42\x42\x42\x3c\x00\x00\x7c\x42\x42\x7c\x40\x40\x00"
            b"\x00\x3c\x42\x42\x52\x4a\x3c\x00\x00\x7c\x42\x42\x7c\x44\x42\x00"
            b"\x00\x3c\x40\x3c\x02\x42\x3c\x00\x00\xfe\x10\x10\x10\x10\x10\x00"
            b"\x00\x42\x42\x42\x42\x42\x3c\x00",
        )

        # Finally, patch compiled code in
        assert mc_addr + len(mc_bytes) <= 65536
        self.patchAddr(mc_addr, mc_bytes)
