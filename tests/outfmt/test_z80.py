# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# © Copyright 2008-2024 José Manuel Rodríguez de la Rosa and contributors.
# See the file CONTRIBUTORS.md for copyright details.
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

from src.outfmt.z80 import Z80Emitter


def test_z80_emitter_generate():
    emitter = Z80Emitter()
    program_bytes = b"\x00" * 100
    entry_point = 0x8000

    # generate(self, loader_bytes, clear_addr, entry_point, program_bytes)
    z80_data = emitter.generate(None, entry_point - 1, entry_point, program_bytes)

    # Header is 30 bytes
    assert len(z80_data) > 30
    assert z80_data[10] == 0x3F  # snapshot.I

    # PC in Z80 version 1 header at offset 6
    # GenSnapshot default PC is 0x1B9E -> PCL=0x9E, PCH=0x1B
    assert z80_data[6] == 0x9E
    assert z80_data[7] == 0x1B

    # End marker
    assert z80_data.endswith(b"\x00\xed\xed\x00")


def test_z80_compression():
    emitter = Z80Emitter()

    # program_bytes with 4 EDs to test compression
    program_bytes = b"\xed\xed\xed\xed"
    entry_point = 0x8000

    z80_data = emitter.generate(None, entry_point - 1, entry_point, program_bytes)

    # The 4 EDs should be compressed to ED ED 04 ED
    assert b"\xed\xed\x04\xed" in z80_data


def test_z80_emitter_emit(tmp_path):
    output_file = tmp_path / "test.z80"
    emitter = Z80Emitter()
    emitter.emit(
        output_filename=str(output_file),
        program_name="test",
        loader_bytes=None,
        entry_point=0x8000,
        program_bytes=b"\x00" * 100,
        aux_bin_blocks=[],
        aux_headless_bin_blocks=[],
    )
    assert output_file.exists()
