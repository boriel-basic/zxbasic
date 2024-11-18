# 48K .Z80 format output module
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


import io

from .codeemitter import CodeEmitter
from .gensnapshot import GenSnapshot


class Z80Emitter(CodeEmitter):
    """Class to emit 48K .Z80 snapshots"""

    def __init__(self):
        """Initializes the .Z80 generation"""

        super().__init__()

    def generate(
        self,
        loader_bytes,
        clear_addr,
        entry_point,
        program_bytes,
    ):
        """Generate the bytes of a .Z80 format snapshot"""

        """
        Format of .Z80 version 1 (the only one we generate here):

        Offset  Length  Description
        ---------------------------
        0       1       A register
        1       1       F register
        2       2       BC register pair (LSB, i.e. C, first)
        4       2       HL register pair
        6       2       Program counter
        8       2       Stack pointer
        10      1       Interrupt register
        11      1       Refresh register (Bit 7 is not significant!)
        12      1       Bit 0  : Bit 7 of the R-register
                        Bit 1-3: Border colour
                        Bit 4  : 1=Basic SamRom switched in
                        Bit 5  : 1=Block of data is compressed
                        Bit 6-7: No meaning
        13      2       DE register pair
        15      2       BC' register pair
        17      2       DE' register pair
        19      2       HL' register pair
        21      1       A' register
        22      1       F' register
        23      2       IY register (Again LSB first)
        25      2       IX register
        27      1       Interrupt flipflop, 0=DI, otherwise EI
        28      1       IFF2 (not particularly important...)
        29      1       Bit 0-1: Interrupt mode (0, 1 or 2)
                        Bit 2  : 1=Issue 2 emulation
                        Bit 3  : 1=Double interrupt frequency
                        Bit 4-5: 1=High video synchronisation
                                 3=Low video synchronisation
                                 0,2=Normal
                        Bit 6-7: 0=Cursor/Protek/AGF joystick
                                 1=Kempston joystick
                                 2=Sinclair 2 Left joystick (or user
                                   defined, for version 3 .z80 files)
                                 3=Sinclair 2 Right joystick

        After that, a run-length compressed stream follows, containing the
        48 KB of the memory. Each block of 5 to 255 bytes that are all equal
        (or 2 to 255 if the repeated bytes are ED) is replaced with ED ED xx yy,
        where xx is the repeat count and yy the byte to repeat. The byte
        following a single ED is not considered eligible as a block.

        After the memory dump, an end marker comes: 00 ED ED 00

        Examples:
          01 01 01 01 01 01 01 -> ED ED 07 01
          ED ED 22 22          -> ED ED 02 ED 22 22
          (the first two ED's must be run-length encoded, otherwise ambiguity
          would arise).
          ED 00 00 00 00 00 00 -> ED 00 ED ED 05 00
          (only the bytes starting after the second 00 are considered for
          compression; the first ED 00 sequence is encoded verbatim).

        """

        snapshot = GenSnapshot(loader_bytes, clear_addr, entry_point, program_bytes)

        z80 = io.BytesIO()

        z80.write(
            bytes(
                (
                    snapshot.A,
                    snapshot.F,
                    snapshot.C,
                    snapshot.B,
                    snapshot.L,
                    snapshot.H,
                    snapshot.PCL,
                    snapshot.PCH,
                    snapshot.SPL,
                    snapshot.SPH,
                    snapshot.I,
                    snapshot.R & 0x7F,
                    ((snapshot.R & 0x80) >> 7) | ((snapshot.outFE & 7) << 1) | 0x20,
                    snapshot.E,
                    snapshot.D,
                    snapshot.C2,
                    snapshot.B2,
                    snapshot.E2,
                    snapshot.D2,
                    snapshot.L2,
                    snapshot.H2,
                    snapshot.A2,
                    snapshot.F2,
                    snapshot.IYL,
                    snapshot.IYH,
                    snapshot.IXL,
                    snapshot.IXH,
                    1 if snapshot.IFF1 else 0,  # IFF1
                    1 if snapshot.IFF2 else 0,  # IFF2
                    snapshot.IM & 3,
                )
            )
        )

        idx: int = 0
        runlength: int = 0
        b: int = -1

        while True:
            if idx == 49152:
                break

            b = snapshot.mem[idx]
            idx += 1
            if idx != 49152 and b == snapshot.mem[idx]:
                # Repetition found
                runlength = 1

                # Find the end of this run
                while idx != 49152 and runlength != 255:
                    if b != snapshot.mem[idx]:
                        break
                    idx += 1
                    runlength += 1

                if runlength < 5 and b != 0xED:
                    # Doesn't qualify for compression
                    z80.write(bytes((b,)) * runlength)
                else:
                    # Must compress
                    z80.write(bytes((0xED, 0xED, runlength, b)))

            else:
                z80.write(bytes((b,)))
                # Store byte after ED and don't consider it for run length
                if b == 0xED and idx != 49152:
                    z80.write(bytes((snapshot.mem[idx],)))
                    idx += 1

        z80.write(b"\0\xed\xed\0")
        return z80.getvalue()

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
        """Save a .Z80 file with the compiled bytes; ignores loader_bytes"""

        output = self.generate(None, entry_point - 1, entry_point, program_bytes)

        # Write output file
        with open(output_filename, "wb") as f:
            f.write(output)
