# 48K .SNA format output module
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


from .codeemitter import CodeEmitter
from .gensnapshot import GenSnapshot


class SnaEmitter(CodeEmitter):
    """Class to write 48K .SNA snapshots"""

    def generate(
        self,
        loader_bytes,
        clear_addr,
        entry_point,
        program_bytes,
    ):
        """
        Format of .SNA file:

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

        A raw memory dump (49152 bytes) follows.

        PC is on the stack. A `retn` instruction should be executed after load.
        """

        snapshot = GenSnapshot(loader_bytes, clear_addr, entry_point, program_bytes)

        # SNA stores the start address in the stack, so SP should be adjusted
        SP = ((snapshot.SPH << 8) | snapshot.SPL) - 2

        sna_data = bytearray(
            (
                snapshot.I,
                snapshot.L2,
                snapshot.H2,
                snapshot.E2,
                snapshot.D2,
                snapshot.C2,
                snapshot.B2,
                snapshot.F2,
                snapshot.A2,
                snapshot.L,
                snapshot.H,
                snapshot.E,
                snapshot.D,
                snapshot.C,
                snapshot.B,
                snapshot.IYL,
                snapshot.IYH,
                snapshot.IXL,
                snapshot.IXH,
                4 if snapshot.IFF1 else 0,
                snapshot.R,
                snapshot.F,
                snapshot.A,
                SP & 0xFF,
                SP >> 8,
                snapshot.IM,
                snapshot.outFE & 7,
            )
        )
        snaHeaderLen = len(sna_data)

        sna_data.extend(snapshot.mem)
        sna_data[SP - 16384 + 0 + snaHeaderLen] = snapshot.PCL
        sna_data[SP - 16384 + 1 + snaHeaderLen] = snapshot.PCH

        return sna_data

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

        sna_data = self.generate(None, entry_point - 1, entry_point, program_bytes)

        # Write output file
        with open(output_filename, "wb") as f:
            f.write(sna_data)
